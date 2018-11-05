describe 'Gratan::Client#apply' do
  context 'when create user with target' do
    subject { client(target_user: /scott/) }

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

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when create user with target (no change)' do
    subject { client(target_user: /mary/) }

    it do
      dsl = <<-RUBY
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

user 'bob', '%', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end
      RUBY

      result = apply(subject) { dsl }
      expect(result).to be_falsey

      expect(show_grants).to match_array []
    end
  end
end
