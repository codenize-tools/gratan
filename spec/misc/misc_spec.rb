describe 'Gratan::Client#apply' do
  context 'when colorize is true' do
    subject { client }

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
      RUBY

      begin
        String.colorize = true
        apply(subject) { dsl }
      ensure
        String.colorize = false
      end

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when set debug' do
    let(:logger) do
      logger = Gratan::Logger.send(:new)
      logger.set_debug(true)
      expect(logger).to receive(:debug).with("[DEBUG] SET SQL_LOG_BIN = 0")
      allow(logger).to receive(:debug).with('[DEBUG] SET SQL_MODE = ""')
      expect(logger).to receive(:debug).with("[DEBUG] SELECT user, host FROM mysql.user")
      expect(logger).to receive(:info).with("GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY 'tiger'")
      expect(logger).to receive(:info).with("GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost' IDENTIFIED BY 'tiger'")
      expect(logger).to receive(:info).with("FLUSH PRIVILEGES")
      logger
    end

    subject { client(logger: logger) }

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
      ].normalize
    end
  end
end
