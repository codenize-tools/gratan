class Gratan::Exporter
  def self.export(client, options = {})
    self.new(client, options).export
  end

  def initialize(client, options = {})
    @client = client
    @options = options
  end

  def export
    grants = []

    each_user do |user, host|
      show_grants(user, host) do |stmt|
        grants << Gratan::GrantParser.parse(stmt)
      end
    end

    pack(grants)
  end

  private

  def each_user
    @client.query('SELECT user, host FROM mysql.user').each do |row|
      yield(row['user'], row['host'])
    end
  end

  def show_grants(user, host)
    user = user.gsub("'", "\\\\'")
    host = host.gsub("'", "\\\\'")

    @client.query("SHOW GRANTS FOR '#{user}'@'#{host}'").each do |row|
      yield(row.values.first)
    end
  end

  def pack(grants)
    packed = {}

    grants.each do |grant|
      user = grant.delete(:user)
      host = grant.delete(:host)
      user_host = [user, host]
      object = grant.delete(:object)

      packed[user_host] ||= {}
      packed[user_host][object] = grant
    end

    packed
  end
end
