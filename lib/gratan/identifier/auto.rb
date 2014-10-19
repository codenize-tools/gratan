class Gratan::Identifier::Auto
  def initialize(output, options = {})
    @output = output
    @options = options

    unless @options[:dry_run]
      @output = output
    end

    @cache = {}
  end

  def identify(user, host)
    if @cache[user]
      password = @cache[user]
    else
      password = mkpasswd
      @cache[user] = password
    end

    puts_password(user, host, password)
    password
  end

  private

  def mkpasswd(len = 8)
    [*1..9, *'A'..'Z', *'a'..'z'].shuffle.slice(0, len).join
  end

  def puts_password(user, host, password)
    open_output do |f|
      f.puts("#{user}@#{host},#{password}")
    end
  end

  def open_output
    return if @options[:dry_run]

    if @output == '-'
      yield($stdout)
      $stdout.flush
    else
      open(@output, 'a') do |f|
        yield(f)
      end
    end
  end
end
