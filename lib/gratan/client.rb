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
end
