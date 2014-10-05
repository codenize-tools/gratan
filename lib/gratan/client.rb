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
        @driver.create_user(*user_host, expected_attrs)
      end
    end

    actual.each do |user_host, attrs|
      @driver.drop_user(*user_host)
    end
  end

  def walk_user(user, host, expected_attrs, actual_attrs)
    expected_objects = expected_attrs[:objects]
    expected_options = expected_attrs[:options]
    actual_objects = actual_attrs[:objects]
    actual_options = actual_attrs[:options]
    walk_options(user, host, expected_options, actual_options)
    # XXX:
    # walk_objects
  end

  def walk_options(user, host, expected_options, actual_options)
    walk_identified(user, host, expected_options[:identified], actual_options[:identified])
    # XXX:
    # walk_required
  end

  def walk_identified(user, host, expected_identified, actual_identified)
    if expected_identified != actual_identified
      @driver.identify(user, host, expected_identified)
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
