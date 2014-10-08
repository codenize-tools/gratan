class Gratan::Identifier::Auto
  def initialize(output, options = {})
    @options = options

    unless @options[:dry_dun]
      if output == '-'
        @output = $stdout
      else
        @output = open(output, 'w')
      end
    end
  end

  def identify(user, host)
    password = mkpasswd
    puts_password(user, host, password)
    password
  end

  private

  def mkpasswd(len = 8)
    [*1..9, *'A'..'Z', *'a'..'z'].shuffle.slice(0, len).join
  end

  def puts_password(user, host, password)
    @output.puts("#{user}@#{host},#{password}") if @output
    @output.flush
  end
end
