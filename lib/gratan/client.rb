class Gratan::Client
  def initialize(options = {})
    @options = options
    client = Mysql2::Client.new(options)
    @driver = Gratan::Driver.new(client, options)
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Gratan::Exporter.export(@driver, options)
    Gratan::DSL.convert(exported, options)
  end

  def apply(file, options = {})
    options = @options.merge(options)
    walk(file, options)
  end

  private

  def walk(file, options)
    expected = load_file(file)
    actual = Gratan::Exporter.export(@driver, options)

    expected.each do |user_host, expected_attrs|
      actual_attrs = actual.delete(user_host)

      if actual_attrs
        walk_user(*user_host, expected_attrs, actual_attrs)
      else
        create_user(*user_host, expected_attrs)
      end
    end

    actual.each do |user_host, attrs|
      drop_user(*user_host)
    end
  end

  def create_user(user, host, attrs)
    # XXX: Add password proc
    @driver.create_user(user, host, attrs)
  end

  def drop_user(user, host)
    @driver.drop_user(user, host)
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
    if expected_identified != actual_identified
      @driver.identify(user, host, expected_identified)
    end
  end

  def walk_required(user, host, expected_required, actual_required)
    if expected_required != actual_required
      @driver.set_require(user, host, expected_required)
    end
  end

  def walk_objects(user, host, expected_objects, actual_objects)
    expected_objects.each do |object, expected_options|
      actual_options = actual_objects.delete(object)

      if actual_options
        # XXX:
      else
        # XXX:
      end
    end

    actual_objects.each do |object, options|
      @driver.revoke_all(user, host, object, options[:with])
    end
  end

  def load_file(file)
    if file.kind_of?(String)
      open(file) do |f|
        Gratan::DSL.parse(f.read, file)
      end
    elsif file.respond_to?(:read)
      Gratan::DSL.parse(file.read, file.path)
    else
      raise TypeError, "can't convert #{file} into File"
    end
  end
end
