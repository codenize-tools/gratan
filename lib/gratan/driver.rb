class Gratan::Driver
  include Gratan::Logger::Helper

  def initialize(client, options = {})
    @client = client
    @options = options
  end

  def each_user
    read('SELECT user, host FROM mysql.user').each do |row|
      yield(row['user'], row['host'])
    end
  end

  def show_grants(user, host)
    read("SHOW GRANTS FOR #{quote_user(user, host)}").each do |row|
      yield(row.values.first)
    end
  end

  def create_user(user, host, options = {})
    objects = options[:objects]
    grant_options = options[:options]

    objects.each do |object, object_options|
      grant(user, host, object, grant_options.merge(object_options))
    end
  end

  def drop_user(user, host)
    sql = "DROP USER #{quote_user(user, host)}"
    delete(sql)
  end

  def grant(user, host, object, options)
    privs = options.fetch(:privs)
    identified = options[:identified]
    required = options[:required]
    with_option = options[:with]

    sql = 'GRANT %s ON %s TO %s' % [
      privs.join(', '),
      object,
      quote_user(user, host),
    ]

    sql << " IDENTIFIED BY #{quote_identifier(identified)}" if identified
    sql << " REQUIRE #{required}" if required
    sql << " WITH #{with_option}" if with_option

    update(sql)
  end

  def identify(user, host, identifier)
    sql = 'GRANT USAGE ON *.* TO %s IDENTIFIED BY %s' % [
      quote_user(user, host),
      quote_identifier(identifier),
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
      privs << 'GRANT OPTION'
    end

    sql = 'REVOKE %s ON %s FROM %s' % [
      privs.join(', '),
      object,
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
        coount = $1
      end

      options << [name, count].join(' ')
    end

    unless options.empty?
      grant(user, host, object, :privs => ['USAGE'], :with => options.join(' '))
    end
  end

  private

  def read(sql)
    log(:debug, sql)
    @client.query(sql)
  end

  def update(sql)
    log(:info, sql, :green)
    @client.query(sql) unless @options[:dry_run]
  end

  def delete(sql)
    log(:info, sql, :red)
    @client.query(sql) unless @options[:dry_run]
  end

  def escape(str)
    @client.escape(str)
  end

  def quote_user(user, host)
    "'%s'@'%s'" % [escape(user), escape(host)]
  end

  def quote_identifier(identifier)
    identifier ||= ''

    unless identifier =~ /\APASSWORD\s+'.+'\z/
      identifier = "'#{escape(identifier)}'"
    end

    identifier
  end
end
