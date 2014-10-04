module Gratan::DSL::Validator
  def __validate(errmsg)
    raise __identify(errmsg) unless yield
  end

  def __identify(errmsg)
    if @error_identifier
      errmsg = "#{@error_identifier}: #{errmsg}"
    end

    return errmsg
  end
end
