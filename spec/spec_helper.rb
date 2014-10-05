$: << File.expand_path('..', __FILE__)

if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'gratan'
require 'tempfile'
require 'timecop'

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

def select_users(client)
  users = []

  client.query('SELECT user, host FROM mysql.user').each do |row|
    users << [row['user'], row['host']]
  end

  users
end

def clean_grants
  mysql do |client|
    select_users(client).each do |user, host|
      next if IGNORE_USER =~ user
      user_host =  "'%s'@'%s'" % [client.escape(user), client.escape(host)]
      client.query("DROP USER #{user_host}")
    end
  end
end

def show_grants
  grants = []

  mysql do |client|
    select_users(client).each do |user, host|
      next if IGNORE_USER =~ user
      user_host =  "'%s'@'%s'" % [client.escape(user), client.escape(host)]

      client.query("SHOW GRANTS FOR #{user_host}").each do |row|
        grants << row.values.first
      end
    end
  end

  grants.sort
end

def client(user_options = {})
  if user_options[:ignore_user]
    user_options[:ignore_user] = Regexp.union(IGNORE_USER, user_options[:ignore_user])
  end

  options = {
    host: 'localhost',
    username: 'root',
    ignore_user: IGNORE_USER,
    logger: Logger.new('/dev/null'),
  }

  if ENV['DEBUG']
    logger = Gratan::Logger.instance
    logger.set_debug(true)

    options.update(
      debug: true,
      logger: logger
    )
  end

  options = options.merge(user_options)
  Gratan::Client.new(options)
end

def tempfile(content, options = {})
  basename = "#{File.basename __FILE__}.#{$$}"
  basename = [basename, options[:ext]] if options[:ext]

  Tempfile.open(basename) do |f|
    f.puts(content)
    f.flush
    f.rewind
    yield(f)
  end
end

def apply(cli = client)
  tempfile(yield) do |f|
    cli.apply(f.path)
  end
end
