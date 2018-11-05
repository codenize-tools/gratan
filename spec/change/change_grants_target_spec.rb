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

  context 'when grant privs with target' do
    subject { client(target_user: /bob/) }

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
    grant 'SELECT'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT SELECT ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
      end
  end

  context 'when grant privs with target (no change)' do
    subject { client(target_user: /mary/) }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
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
    grant 'SELECT'
  end
end
      RUBY

      result = apply(subject) { dsl }
      expect(result).to be_falsey

      expect(show_grants).to match_array [
        "GRANT SELECT (user) ON `mysql`.`user` TO 'scott'@'localhost'",
        "GRANT ALL PRIVILEGES ON `test`.* TO 'bob'@'localhost'",
        "GRANT SELECT, INSERT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
        "GRANT UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ].normalize
    end
  end
end
