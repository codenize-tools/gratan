module Gratan::DSL::Validator
  def __validate(errmsg)
    raise __identify(errmsg) unless yield
  end

  def __identify(errmsg)
    if @object_identifier
      errmsg = "#{@object_identifier}: #{errmsg}"
    end

    return errmsg
  end
end
