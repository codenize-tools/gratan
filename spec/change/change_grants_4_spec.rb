describe 'Gratan::Client#apply' do
  context 'when revoke privs with grant option' do
    before do
      apply {
        <<-RUBY
user 'scott', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end

  on 'test.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }
    end

    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost' do
  on '*.*' do
    grant 'USAGE'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT USAGE ON *.* TO 'scott'@'localhost'",
      ]
    end
  end
end
