class Gratan::DSL
  def self.convert(exported, options = {})
    Gratan::DSL::Converter.convert(exported, options)
  end
end
