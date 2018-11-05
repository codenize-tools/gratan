describe 'Gratan::Client#apply' do
  context 'when change privs (multi hosts)' do
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

user 'scott', '%', identified: 'tiger', required: 'SSL' do
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

    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', ['localhost', '%', '127.0.0.1'], required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'UPDATE'
    grant 'INSERT'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT INSERT, UPDATE ON `test`.* TO 'scott'@'%'",
        "GRANT INSERT, UPDATE ON `test`.* TO 'scott'@'127.0.0.1'",
        "GRANT INSERT, UPDATE ON `test`.* TO 'scott'@'localhost'",
        "GRANT SELECT, DELETE ON *.* TO 'scott'@'%' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT SELECT, DELETE ON *.* TO 'scott'@'127.0.0.1' REQUIRE SSL",
        "GRANT SELECT, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when no change privs (multi hosts)' do
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

user 'scott', '%', identified: 'tiger', required: 'SSL' do
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

    subject { client }

    it do
      result = apply(subject) {
        <<-RUBY
user 'scott', ['localhost', '%'], required: 'SSL' do
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

      expect(result).to be_falsey

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'%'",
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'%' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'%'",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end
end
