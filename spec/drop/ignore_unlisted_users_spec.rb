describe 'Gratan::Client#apply' do
  before(:each) do
    apply {
      <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on '*.*' do
    grant 'SELECT'
  end
end

user 'bob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'jimbob', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end
end
      RUBY
    }
  end

  context 'when grant privs with ignore_unlisted_users' do
    subject { client(ignore_unlisted_users: true) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on '*.*' do
    grant 'SELECT'
  end
end

user 'jimbob', 'localhost', dropped: true
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT USAGE ON *.* TO 'bob'@'localhost'",
      ]
    end
  end
end
