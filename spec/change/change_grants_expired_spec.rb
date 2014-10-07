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
        "GRANT SELECT (user), UPDATE (host) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
      ]
    end
  end
end
