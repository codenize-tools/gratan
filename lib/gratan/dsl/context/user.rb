class Gratan::DSL::Context::User
  include Gratan::DSL::Validator

  attr_reader :result

  def initialize(user, host, &block)
    @error_identifier = "User `#{user}@#{host}`"
    @user = user
    @host = host
    @result = {}
    instance_eval(&block)
  end

  def on(name, options = {}, &block)
    name = name.kind_of?(Regexp) ? name : name.to_s

    __validate("Object `#{name}` is already defined") do
      not @result.has_key?(name)
    end

    grant = {:privs => Gratan::DSL::Context::On.new(@user, @host, name, &block).result}
    grant[:with] = options[:with] if options[:with]
    @result[name] = grant
  end
end
