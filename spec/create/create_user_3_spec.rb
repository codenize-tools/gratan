describe 'Gratan::Client#apply' do
  context 'when create user' do
    subject { client(dry_run: true) }

    it do
      result = apply(subject) {
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

      expect(result).to be_falsey
      expect(show_grants).to match_array []
    end
  end

  context 'when add user' do
    before do
      apply {
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

    subject { client(dry_run: true) }

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
      ].normalize
    end
  end

  context 'when create user with grant option' do
    subject { client(dry_run: true) }

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

      expect(show_grants).to match_array []
    end
  end
end
