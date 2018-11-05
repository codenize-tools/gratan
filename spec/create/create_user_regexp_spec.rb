describe 'Gratan::Client#apply' do
  context 'when create user using regexp' do
    subject { client }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on /\\Agratan_test\\.(foo|bar)\\z/ do
    grant 'SELECT'
    grant 'INSERT'
  end

  on /\\Agratan_test\\.z/ do
    grant 'UPDATE'
    grant 'DELETE'
  end
end
      RUBY

      create_tables(:foo, :bar, :zoo, :baz) do
        apply(subject) { dsl }

        expect(show_grants).to match_array [
          "GRANT SELECT, INSERT ON `gratan_test`.`bar` TO 'scott'@'localhost'",
          "GRANT SELECT, INSERT ON `gratan_test`.`foo` TO 'scott'@'localhost'",
          "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
          "GRANT UPDATE, DELETE ON `gratan_test`.`zoo` TO 'scott'@'localhost'",
          "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        ].normalize
      end
    end
  end

  context 'when create user using regexp (no privileges)' do
    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with("[WARN] there was no privileges to grant to 'scott'@'localhost'")
      logger
    end

    subject { client(logger: logger) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on /\\Agratan_test\\.x(foo|bar)\\z/ do
    grant 'SELECT'
    grant 'INSERT'
  end
end
      RUBY

      create_tables(:foo, :bar, :zoo, :baz) do
        apply(subject) { dsl }

        expect(show_grants).to match_array []
      end
    end
  end
end
