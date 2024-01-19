class Gratan::Driver
  include Gratan::Logger::Helper

  ER_NO_SUCH_TABLE = 1146

  def initialize(client, options = {})
    @client = client
    @options = options
  end

  def each_user
    query('SELECT user, host FROM mysql.user').each do |row|
      yield(row['user'], row['host'])
    end
  end

  def show_grants(user, host)
    query("SHOW GRANTS FOR #{quote_user(user, host)}").each do |row|
      yield(row.values.first)
    end
  end

  def show_create_user(user, host)
    query("SHOW CREATE USER #{quote_user(user, host)}").first.values.first
  end

  def show_databases
    query("SHOW DATABASES").map {|i| i.values.first }
  end

  def show_tables(database)
    query("SHOW TABLES FROM `#{database}`").map {|i| i.values.first }
  rescue Mysql2::Error => e
    raise e if e.error_number != 1102

    log(:debug, e.message)
    []
  end

  def show_all_tables
    @all_tables ||= show_databases.map {|database|
      show_tables(database).map do |table|
        "#{database}.#{table}"
      end
    }.flatten
  end

  def expand_object(object_or_regexp)
    if object_or_regexp.kind_of?(Regexp)
      objects = show_all_tables.select {|i| i =~ object_or_regexp }
    else
      objects = [object_or_regexp]
    end

    objects.select do |object|
      object !~ @options[:ignore_object]
    end
  end

  def flush_privileges
    update("FLUSH PRIVILEGES")
  end

  def create_user(user, host, options = {})
    objects = options[:objects]
    identified = options[:options][:identified]
    required = options[:required]
    with_option = options[:with]
    auth_plugin = options[:auth_plugin] || "mysql_native_password"
    grant_options = options[:options]
    granted = false

    sql = "CREATE USER #{quote_user(user, host)}"
    sql << " IDENTIFIED WITH #{auth_plugin} AS #{quote_identifier(identified)}" if identified
    sql << " REQUIRE #{required}" if required
    sql << " WITH #{with_option}" if with_option
    update(sql)

    objects.each do |object_or_regexp, object_options|
      expand_object(object_or_regexp).each do |object|
        grant(user, host, object, grant_options.merge(object_options))
        granted = true
      end
    end

    unless granted
      log(:warn, "there was no privileges to grant to #{quote_user(user, host)}", :color => :yellow)
    end
  end

  def drop_user(user, host)
    sql = "DROP USER #{quote_user(user, host)}"
    delete(sql)
  end

  def grant(user, host, object, options)
    privs = options.fetch(:privs)
    required = options[:required]
    with_option = options[:with]

    sql = 'GRANT %s ON %s TO %s' % [
      privs.join(', '),
      quote_object(object),
      quote_user(user, host),
    ]

    sql << " REQUIRE #{required}" if required
    sql << " WITH #{with_option}" if with_option
    begin
      update(sql)
    rescue Mysql2::Error => e
      if @options[:ignore_not_exist] and e.error_number == ER_NO_SUCH_TABLE
        log(:warn, e.message, :color => :yellow)
      else
        raise e
      end
    end
  end

  def identify(user, host, identifier, auth_plugin = "mysql_native_password")
    sql = "ALTER USER %s IDENTIFIED WITH #{auth_plugin} AS %s" % [
      quote_user(user, host),
      quote_identifier(identifier),
    ]

    update(sql)

    if (identifier || '').empty?
      set_password(user, host, identifier)
    end
  end

  def set_password(user, host, password, options = {})
    password ||= ''

    unless options[:hash]
      password = "SELECT CONCAT('*', UPPER(SHA1(UNHEX(SHA1('#{escape(password)}'))))) AS PASSWORD"
    end

    sql = 'SET PASSWORD FOR %s = %s' % [
      quote_user(user, host),
      password,
    ]

    update(sql)
  end

  def set_require(user, host, required)
    required ||= 'NONE'

    sql = 'GRANT USAGE ON *.* TO %s REQUIRE %s' % [
      quote_user(user, host),
      required
    ]

    update(sql)
  end

  def revoke(user, host, object, options = {})
    privs = options.fetch(:privs)
    with_option = options[:with]

    if with_option =~ /\bGRANT\s+OPTION\b/i
      revoke0(user, host, object, ['GRANT OPTION'])

      if privs.length == 1 and privs[0] =~ /\AUSAGE\z/i
        return
      end
    end

    revoke0(user, host, object, privs)
  end

  def revoke0(user, host, object, privs)
    sql = 'REVOKE %s ON %s FROM %s' % [
      privs.join(', ').gsub('\'', '').strip,
      quote_object(object),
      quote_user(user, host),
    ]

    delete(sql)
  end

  def update_with_option(user, host, object, with_option)
    options = []

    if with_option =~ /\bGRANT\s+OPTION\b/i
      options << 'GRANT OPTION'
    else
      revoke(user, host, object, :privs => ['GRANT OPTION'])
    end

    %w(
      MAX_QUERIES_PER_HOUR
      MAX_UPDATES_PER_HOUR
      MAX_CONNECTIONS_PER_HOUR
      MAX_USER_CONNECTIONS
    ).each do |name|
      count = 0

      if with_option =~ /\b#{name}\s+(\d+)\b/i
        count = $1
      end

      options << [name, count].join(' ')
    end

    unless options.empty?
      grant(user, host, object, :privs => ['USAGE'], :with => options.join(' '))
    end
  end

  def disable_log_bin_local
    unless @options[:skip_disable_log_bin]
      query('SET SQL_LOG_BIN = 0')
    end
  end

  def override_sql_mode
    if @options[:override_sql_mode]
      query('SET SQL_MODE = ""')
    end
  end

  def set_wait_timeout
    if @options[:wait_timeout]
      query("SET @@wait_timeout = #{@options[:wait_timeout]}")
    end
  end

  private

  def query(sql)
    log(:debug, sql, :dry_run => false)
    @client.query(sql)
  end

  def update(sql)
    log(:info, sql, :color => :green)
    @client.query(sql) unless @options[:dry_run]
  end

  def delete(sql)
    log(:info, sql, :color => :red)
    @client.query(sql) unless @options[:dry_run]
  end

  def escape(str)
    @client.escape(str)
  end

  def quote_user(user, host)
    "'%s'@'%s'" % [escape(user), escape(host)]
  end

  def quote_object(object)
    if object =~ /\A(FUNCTION|PROCEDURE)\s+/i
      object_type, object = object.split(/\s+/, 2)
      object_type << ' '
    else
      object_type = ''
    end

    object_type + object.split('.', 2).map {|i| i == '*' ? i : "`#{i}`" }.join('.')
  end

  def quote_identifier(identifier)
    identifier ||= ''

    unless identifier =~ /\APASSWORD\s+'.+'\z/
      identifier = "'#{escape(identifier)}'"
    end

    identifier
  end
end
