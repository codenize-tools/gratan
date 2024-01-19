class Gratan::Client
  include Gratan::Logger::Helper

  def initialize(options = {})
    @options = options
    @options[:identifier] ||= Gratan::Identifier::Null.new
    client = Mysql2::Client.new(options)
    @driver = Gratan::Driver.new(client, options)
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Gratan::Exporter.export(@driver, options)

    if options[:chunk_by_user]
      exported = chunk_by_user(exported)
    end

    if block_given?
      exported.sort_by {|user_host, attrs|
        user_host[0].empty? ? 'root' : user_host[0]
      }.chunk {|user_host, attrs|
        user_host[0].empty? ? 'root' : user_host[0]
      }.each {|user, grants|
        h = {}
        grants.sort_by {|k, v| k }.each {|k, v| h[k] = v }
        dsl = Gratan::DSL.convert(h, options)
        yield(user, dsl)
      }
    else
      Gratan::DSL.convert(exported, options)
    end
  end

  def chunk_by_user(exported)
    chunked = {}

    exported.sort_by {|user_host, attrs|
      user_host[0]
    }.chunk {|user_host, attrs|
      user_host[0]
    }.each {|user, grants|
      merged_attrs = {}
      hosts = []

      grants.each do |user_host, attrs|
        hosts << user_host[1]
        merged_attrs.deep_merge!(attrs)
      end

      user_host = [user, hosts.sort]
      chunked[user_host] = merged_attrs
    }

    chunked
  end

  def apply(file, options = {})
    options = @options.merge(options)

    in_progress do
      walk(file, options)
    end
  end

  private

  def walk(file, options)
    expected = load_file(file, options)
    actual = Gratan::Exporter.export(@driver, options.merge(:with_identifier => true))

    expected.each do |user_host, expected_attrs|
      next if user_host[0] =~ options[:ignore_user]

      if options[:target_user]
        next unless user_host[0] =~ options[:target_user]
      end

      actual_attrs = actual.delete(user_host)

      if actual_attrs
        walk_user(*user_host, expected_attrs, actual_attrs)
      else
        create_user(*user_host, expected_attrs)
      end
    end

    actual.each do |user_host, attrs|
      next if user_host[0] =~ options[:ignore_user]

      if options[:target_user]
        next unless user_host[0] =~ options[:target_user]
      end

      drop_user(*user_host)
    end
  end

  def create_user(user, host, attrs)
    attrs[:options] ||= {}

    unless attrs[:options].has_key?(:identified)
      identified = @options[:identifier].identify(user, host)

      if identified
        attrs = attrs.dup
        attrs[:options] = attrs[:options].dup
        attrs[:options][:identified] = identified
      end
    end

    @driver.create_user(user, host, attrs)
    update!
  end

  def drop_user(user, host)
    @driver.drop_user(user, host)
    update!
  end

  def walk_user(user, host, expected_attrs, actual_attrs)
    walk_options(user, host, expected_attrs[:options], actual_attrs[:options])
    walk_objects(user, host, expected_attrs[:objects], actual_attrs[:objects])
  end

  def walk_options(user, host, expected_options, actual_options)
    if expected_options.has_key?(:identified)
      walk_identified(user, host, expected_options[:identified], actual_options[:identified])
    end

    walk_required(user, host, expected_options[:required], actual_options[:required])
  end

  def walk_identified(user, host, expected_identified, actual_identified)
    if actual_identified == '<secret>'
      unless @options[:ignore_password_secret]
        log(:warn, "cannot change the password (`<secret>`)", :color => :yellow)
      end
    elsif expected_identified != actual_identified
      @driver.identify(user, host, expected_identified)
      update!
    end
  end

  def walk_required(user, host, expected_required, actual_required)
    if expected_required != actual_required
      @driver.set_require(user, host, expected_required)
      update!
    end
  end

  def walk_objects(user, host, expected_objects, actual_objects)
    expected_objects.each do |object_or_regexp, expected_options|
      @driver.expand_object(object_or_regexp).each do |object|
        expected_options ||= {}
        actual_options = actual_objects.delete(object)

        if actual_options
          walk_object(user, host, object, expected_options, actual_options)
        else
          @driver.grant(user, host, object, expected_options)
          update!
        end
      end
    end

    actual_objects.each do |object, options|
      options ||= {}
      @driver.revoke(user, host, object, options)
      update!
    end
  end

  def walk_object(user, host, object, expected_options, actual_options)
    walk_with_option(user, host, object, expected_options[:with], actual_options[:with])
    walk_privs(user, host, object, expected_options[:privs], actual_options[:privs])
  end

  def walk_with_option(user, host, object, expected_with_option, actual_with_option)
    expected_with_option = (expected_with_option || '').upcase
    actual_with_option = (actual_with_option || '').upcase

    if expected_with_option != actual_with_option
      @driver.update_with_option(user, host, object, expected_with_option)
      update!
    end
  end

  def walk_privs(user, host, object, expected_privs, actual_privs)
    expected_privs = normalize_privs(expected_privs)
    actual_privs = normalize_privs(actual_privs)

    revoke_privs = actual_privs - expected_privs
    grant_privs = expected_privs - actual_privs

    unless revoke_privs.empty?
      if revoke_privs.length == 1 and revoke_privs[0] == 'USAGE' and not grant_privs.empty?
        # nothing to do
      else
        @driver.revoke(user, host, object, :privs => revoke_privs)
        update!
      end
    end

    unless grant_privs.empty?
      @driver.grant(user, host, object, :privs => grant_privs)
      update!
    end
  end

  def normalize_privs(privs)
    privs.map do |priv|
      priv = priv.split('(', 2)
      priv[0].upcase!

      if priv[1]
        priv[1] = priv[1].split(',').map {|i| i.gsub(')', '').strip }.sort.join(', ')
        priv[1] << ')'
      end

      priv = priv.join('(')

      if priv == 'ALL'
        priv = 'ALL PRIVILEGES'
      end

      priv
    end
  end

  def load_file(file, options)
    if file.kind_of?(String)
      open(file) do |f|
        Gratan::DSL.parse(f.read, file, options)
      end
    elsif file.respond_to?(:read)
      Gratan::DSL.parse(file.read, file.path, options)
    else
      raise TypeError, "can't convert #{file} into File"
    end
  end

  def in_progress
    updated = false

    begin
      @driver.disable_log_bin_local
      @driver.override_sql_mode
      @driver.set_wait_timeout
      @updated = false
      yield
      updated = @updated
      @driver.flush_privileges if updated
    ensure
      @updated = nil
    end

    if @options[:dry_run]
      false
    else
      updated
    end
  end

  def update!
    @updated = true
  end
end
