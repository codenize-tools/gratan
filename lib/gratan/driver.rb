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
    read("SHOW GRANTS FOR '#{escape(user)}'@'#{escape(host)}'").each do |row|
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
    sql = "DROP USER '%s'@'%s'" % [escape(user), escape(host)]
    delete(sql)
  end

  def grant(user, host, object, options = {})
    privs = options[:privs]
    identified = options[:identified]
    required = options[:required]
    with_option = options[:with]

    sql = 'GRANT %s ON %s TO %s' % [
      privs.join(', '),
      object,
      "'%s'@'%s'" % [escape(user), escape(host)],
    ]

    sql << "IDENTIFIED BY #{identified}" if identified
    sql << "REQUIRE #{required}" if required
    sql << "WITH #{with_option}" if with_option

    update(sql)
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
end
