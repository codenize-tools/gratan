describe 'Gratan::Client#apply' do
  context 'when grant privs (ignore_not_exist: true)' do
    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with("[WARN] Table 'yamada.taro' doesn't exist")
      logger
    end

    subject do
      client(
        ignore_not_exist: true,
        logger: logger
      )
    end

    before do
      apply {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end
end
        RUBY
      }
    end

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'yamada.taro' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when grant privs (ignore_not_exist: false)' do
    subject { client(ignore_not_exist: false) }

    before do
      apply {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end
end
        RUBY
      }
    end

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'yamada.taro' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end
      RUBY

      expect {
        apply(subject) { dsl }
      }.to raise_error("Table 'yamada.taro' doesn't exist")
    end
  end
end
