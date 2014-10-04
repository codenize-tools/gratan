class Gratan::Client
  def initialize(options = {})
    @options = options
    @client = Mysql2::Client.new(options)
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Gratan::Exporter.export(@client, options)
    Gratan::DSL.convert(exported, options)
  end

  def apply(file, options = {})
    options = @options.merge(options)
    walk(file, options)
  end

  private

  def walk(file, options)
    expected = load_file(file)
    actual = Gratan::Exporter.export(@client, options)

    require 'pp'
    pp expected
    puts '-' * 32
    pp actual
    # XXX:
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
