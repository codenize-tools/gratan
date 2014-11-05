class Gratan::DSL::Converter
  def self.convert(exported, options = {})
    self.new(exported, options).convert
  end

  def initialize(exported, options = {})
    @exported = exported
    @options = options
  end

  def convert
    @exported.map {|user_host, attrs|
      output_user(user_host, attrs)
    }.join("\n")
  end

  private

  def output_user(user_host, attrs)
    user, host = user_host
    objects, options = attrs.values_at(:objects, :options)
    options = output_user_options(options)

    <<-EOS
user #{user.inspect}, #{host.inspect}#{options}do
  #{output_objects(objects)}
end
    EOS
  end

  def output_user_options(options)
    if options.empty?
      ' '
    else
      options = strip_hash_brace(options.inspect)
      ", #{options} "
    end
  end

  def output_objects(objects)
    objects.sort_by {|k, v| k }.map {|object, grant|
      options = output_object_options(grant)

      <<-EOS
  on #{object.inspect}#{options}do
    #{output_grant(grant)}
  end
      EOS
    }.join("\n").strip
  end

  def output_object_options(grant)
    with_option = grant.delete(:with)

    if with_option
      options = strip_hash_brace({:with => with_option}.inspect)
      ", #{options} "
    else
      ' '
    end
  end

  def output_grant(grant)
    grant[:privs].sort.map {|priv|
      <<-EOS
    grant #{priv.inspect}
      EOS
    }.join.strip
  end

  def strip_hash_brace(hash_str)
    hash_str.sub(/\A\{/, '').sub(/\}\z/, '')
  end
end
