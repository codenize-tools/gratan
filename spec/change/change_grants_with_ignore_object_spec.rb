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

  context 'when grant privs with ignore_object' do
    subject { client(ignore_object: /user/) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
    grant 'UPDATE (host)' # ignore
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

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
    end
  end

  context 'when grant privs with ignore_object (2)' do
    subject { client(ignore_object: /user2/) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'mysql.user' do
    grant 'SELECT (user)'
    grant 'UPDATE (host)'
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

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT (user), UPDATE (host) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
    end
  end
end
