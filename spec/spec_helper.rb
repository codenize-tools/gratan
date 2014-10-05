$: << File.expand_path('..', __FILE__)
require 'gratan'

IGNORE_USER = /\A(|root)\z/

RSpec.configure do |config|
  config.before(:each) do
    clean_grants
  end
end

def mysql
  client = nil
  retval = nil

  begin
    client = Mysql2::Client.new(host: 'localhost', username: 'root')
    retval = yield(client)
  ensure
    client.close if client
  end

  retval
end

def clean_grants
  mysql do |client|
    users = []

    client.query('SELECT user, host FROM mysql.user').each do |row|
      users << [row['user'], row['host']]
    end

    users.each do |user, host|
      next if IGNORE_USER =~ user
      user_host = "'%s'@'%s'" % [client.escape(user), client.escape(host)]
      client.query("DROP USER #{user_host}")
    end
  end
end
