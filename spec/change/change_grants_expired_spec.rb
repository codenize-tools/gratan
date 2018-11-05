describe 'Gratan::Client#apply' do
  before(:each) do
    apply {
      <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end

  on 'test.*' do
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
  end
end
      RUBY
    }
  end

  context 'when object has expired' do
    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with('[WARN] User `scott@localhost`: Object `test.*` has expired')
      logger
    end

    subject do
      client(
        enable_expired: true,
        logger: logger
      )
    end

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end

  on 'test.*', expired: '2014/10/06' do
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
  end
end
      RUBY

      Timecop.freeze(Time.parse('2014/10/06')) do
        apply(subject) { dsl }
      end

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when object has not expired' do
    subject { client(enable_expired: true) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end

  on 'test.*', expired: '2014/10/06' do
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
  end
end
      RUBY

      Timecop.freeze(Time.parse('2014/10/05 23:59:59')) do
        result = apply(subject) { dsl }
        expect(result).to be_falsey
      end

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when enable_expired is false' do
    subject { client(enable_expired: false) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end

  on 'test.*', expired: '2014/10/06' do
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
  end
end
      RUBY


      Timecop.freeze(Time.parse('2014/10/10')) do
        result = apply(subject) { dsl }
        expect(result).to be_falsey
      end

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end
end
