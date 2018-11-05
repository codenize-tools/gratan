describe 'Gratan::Client#apply' do
  context 'when create user with auto identify' do
    let(:auto_identifier) do
      identifier = Gratan::Identifier::Auto.new('/dev/null')
      allow(identifier).to receive(:mkpasswd) { 'foobarzoo' }
      identifier
    end

    subject { client(identifier: auto_identifier) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost' do
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
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*6F498C84277BCC2089932690304BD4EDABC74547'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when create user with auto identify (dry-run)' do
    let(:auto_identifier) do
      identifier = Gratan::Identifier::Auto.new('/dev/null')
      allow(identifier).to receive(:mkpasswd) { 'foobarzoo' }
      identifier
    end

    subject { client(identifier: auto_identifier, dry_run: true) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost' do
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

      expect(show_grants).to match_array []
    end
  end

  context 'when create user with csv identify' do
    let(:csv_identifier) do
      identifier = nil

      csv = <<-CSV
scott@localhost,foobarzoo
      CSV

      tempfile(csv) do |f|
        identifier = Gratan::Identifier::CSV.new(f.path)
      end

      identifier
    end

    subject { client(identifier: csv_identifier) }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost' do
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
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*6F498C84277BCC2089932690304BD4EDABC74547'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when create user with csv identify (there is no password)' do
    let(:logger) do
      logger = Logger.new('/dev/null')
      expect(logger).to receive(:warn).with('[WARN] password for `scott@localhost` can not be found')
      logger
    end

    let(:csv_identifier) do
      identifier = nil

      csv = <<-CSV
scott2@localhost,foobarzoo
      CSV

      tempfile(csv) do |f|
        identifier = Gratan::Identifier::CSV.new(f.path, logger: logger)
      end

      identifier
    end

    subject do
      client(
        identifier: csv_identifier,
        logger: logger
      )
    end

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost' do
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
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ]
    end
  end
end
