$: << File.expand_path('..', __FILE__)

require 'gratan'
require 'tempfile'
require 'timecop'

IGNORE_USER = /\A(|root)\z/
TEST_DATABASE = 'gratan_test'

RSpec.configure do |config|
  config.before(:each) do
    clean_grants
  end
end

def mysql80?
  ENV['MYSQL80'] == '1'
end

MYSQL_PORT = mysql80? ? 3308 : 3307

def mysql
  client = nil
  retval = nil

  begin
    client = Mysql2::Client.new(host: '127.0.0.1', username: 'root', port: MYSQL_PORT)
    retval = yield(client)
  ensure
    client.close if client
  end

  retval
end

def create_database(client)
  client.query("CREATE DATABASE #{TEST_DATABASE}")
end

def drop_database(client)
  client.query("DROP DATABASE IF EXISTS #{TEST_DATABASE}")
end

def create_table(client, table)
  client.query("CREATE TABLE #{TEST_DATABASE}.#{table} (id INT)")
end

def create_function(client, func)
  client.query("CREATE FUNCTION #{TEST_DATABASE}.#{func}() RETURNS INT RETURN 1")
end

def create_procedure(client, prcd)
  client.query("CREATE PROCEDURE #{TEST_DATABASE}.#{prcd}() SELECT 1")
end

def create_tables(*tables)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      tables.each {|i| create_table(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
end

def create_functions(*funcs)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      funcs.each {|i| create_function(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
end

def create_procedures(*prcds)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      prcds.each {|i| create_procedure(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
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

  if mysql80?
    grants.each do |grant|
    end
  end

  grants.sort
end

def client(user_options = {})
  if user_options[:ignore_user]
    user_options[:ignore_user] = Regexp.union(IGNORE_USER, user_options[:ignore_user])
  end

  options = {
    host: '127.0.0.1',
    username: 'root',
    port: MYSQL_PORT,
    ignore_user: IGNORE_USER,
    logger: Logger.new('/dev/null'),
  }

  if mysql80?
    options.update(
      override_sql_mode: true,
      use_show_create_user: true,
    )
  end

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

class Array
  def normalize
    if mysql80?
      self.map do |i|
        i.sub(/ IDENTIFIED BY PASSWORD '[^']+'/, '')
         .sub(/ REQUIRE \w+\b/, '')
         .sub(/ WITH GRANT OPTION [\w ]+\z/, ' WITH GRANT OPTION')
      end
    else
      self
    end
  end
end
