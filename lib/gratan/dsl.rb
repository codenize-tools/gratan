class Gratan::DSL
  def self.convert(exported, options = {})
    Gratan::DSL::Converter.convert(exported, options)
  end

  def self.parse(dsl, path, options = {})
    Gratan::DSL::Context.eval(dsl, path, options).result
  end
end
