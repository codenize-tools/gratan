describe 'Gratan::Client#apply' do
  before(:each) do
    apply {
      <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY
    }
  end

  context 'when update password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: '123', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost', identified: '456' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'localhost' IDENTIFIED BY PASSWORD '*531E182E2F72080AB0740FE2F2D689DBE0146E04' WITH GRANT OPTION",
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when remove password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: nil, required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'localhost' WITH GRANT OPTION",
        "GRANT USAGE ON *.* TO 'scott'@'localhost' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when skip update password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'localhost' WITH GRANT OPTION",
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when update require' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', required: 'X509' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost', required: 'SSL' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'localhost' REQUIRE SSL WITH GRANT OPTION",
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE X509",
      ].normalize
    end
  end

  context 'when update with option' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*', with: 'GRANT OPTION MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT ALL PRIVILEGES ON *.* TO 'bob'@'localhost'",
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL WITH GRANT OPTION MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4",
      ].normalize
    end
  end
end
