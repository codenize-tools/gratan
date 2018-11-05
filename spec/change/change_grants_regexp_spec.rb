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

  context 'when change privs using regexp' do
    subject { client }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
  end

  on 'test.*' do
    grant 'UPDATE'
    grant 'DELETE'
  end

  on /\\Agratan_test\\.(foo|bar)\\z/ do
    grant 'SELECT'
    grant 'INSERT'
  end
end

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
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
          "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
          "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
          "GRANT SELECT, INSERT ON `gratan_test`.`bar` TO 'scott'@'localhost'",
          "GRANT SELECT, INSERT ON `gratan_test`.`foo` TO 'scott'@'localhost'",
          "GRANT UPDATE, DELETE ON `gratan_test`.`zoo` TO 'bob'@'localhost'",
          "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
          "GRANT USAGE ON *.* TO 'bob'@'localhost'",
        ].normalize
      end
    end
  end

  context 'when no change privs using regexp' do
    subject { client }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
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

  on /\\Agratan_test\\.x(foo|bar)\\z/ do
    grant 'SELECT'
    grant 'INSERT'
  end
end

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*' do
    grant 'ALL PRIVILEGES'
  end

  on /\\Agratan_test\\.xz/ do
    grant 'UPDATE'
    grant 'DELETE'
  end
end
      RUBY

      create_tables(:foo, :bar, :zoo, :baz) do
        result = apply(subject) { dsl }
        expect(result).to be_falsey

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
end
