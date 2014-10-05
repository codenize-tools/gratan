class Gratan::Driver
  def initialize(client, options = {})
    @client = client
    @options = options
  end

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
end
