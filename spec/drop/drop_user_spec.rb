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

  context 'when drop user' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
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
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ]
    end
  end

  context 'when drop all users' do
    subject { client }

    it do
      apply(subject) { '' }
      expect(show_grants).to match_array []
    end
  end
end
