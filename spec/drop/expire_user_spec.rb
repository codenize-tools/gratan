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

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY
    }
  end

  context 'when has expired' do
    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with('[WARN] User `scott@localhost` has expired')
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
user 'scott', 'localhost', identified: 'tiger', required: 'SSL', expired: '2014/10/06' do
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

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY

      Timecop.freeze(Time.parse('2014/10/06')) do
        apply(subject) { dsl }
      end

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ]
    end
  end

  context 'when has not expired' do
    subject { client(enable_expired: true) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL', expired: '2014/10/06' do
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

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY

      Timecop.freeze(Time.parse('2014/10/05 23:59:59')) do
        apply(subject) { dsl }
      end

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
    end
  end

  context 'when enable_expired is false' do
    subject { client(enable_expired: false) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL', expired: '2014/10/06' do
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

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY

      Timecop.freeze(Time.parse('2014/10/10')) do
        apply(subject) { dsl }
      end

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
    end
  end
end
