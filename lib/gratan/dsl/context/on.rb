class Gratan::DSL::Context::On
  include Gratan::DSL::Validator

  attr_reader :result

  def initialize(user, host, object, &block)
    @error_identifier = "User `#{user}@#{host}` on `#{object}`"
    @result = []
    instance_eval(&block)
  end

  def grant(name, options = {})
    __validate("Grant `#{name}` is already defined") do
      not @result.include?(name)
    end

    @result << name
  end
end
