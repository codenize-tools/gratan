describe 'Gratan::Client#apply' do
  context 'when user does not exist' do
    subject { client }

    it do
      apply(subject) { '' }
      expect(show_grants).to match_array []
    end
  end

  context 'when create user' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
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
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ]
    end
  end

  context 'when add user' do
    before do
      apply(subject) {
        <<-RUBY
user 'bob', '%', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end
        RUBY
      }
    end

    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'bob', '%', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end

user 'scott', 'localhost', identified: 'tiger' do
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
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'%' REQUIRE SSL",
        "GRANT SELECT ON `test`.* TO 'bob'@'%'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ]
    end
  end

  context 'when create user with grant option' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on '*.*', with: 'grant option' do
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
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' WITH GRANT OPTION",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ]
    end
  end
end
