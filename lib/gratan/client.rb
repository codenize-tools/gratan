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

    expected.each do |expected_user_host, expected_attrs|
      actual_user_host, actual_attrs = actual.delete(expected_user_host)

      if actual_user_host
        # XXX:
      else
        @driver.create_user(*expected_user_host, expected_attrs)
      end
    end

    actual.each do |actual_user_host, actual_attrs|
      @driver.drop_user(*actual_user_host)
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
