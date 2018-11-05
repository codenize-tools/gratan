describe 'Gratan::Client#apply' do
  context 'when create user (multi hosts)' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', ['localhost', '127.0.0.1', '192.168.%'], identified: 'tiger' do
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
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'127.0.0.1' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'127.0.0.1'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'192.168.%' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'192.168.%'",
      ].normalize
    end
  end
end
