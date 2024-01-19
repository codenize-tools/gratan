class Gratan::GrantParser
  def initialize(stmt, create_user = nil)
    @stmt = stmt.strip
    @create_user = create_user
    @parsed = {}
  end

  def self.parse(stmt, create_user = nil)
    parser = self.new(stmt, create_user)
    parser.parse!
  end

  def parse!
    parse_grant
    parse_require
    parse_identified
    parse_main
    @parsed
  end

  private

  def parse_grant
    @stmt.slice!(/\s+WITH\s+(.+?)\z/)
    with_option = $1

    if with_option
      @parsed[:with] = with_option.strip
    end
  end

  def parse_require
    @stmt.slice!(/\s+REQUIRE\s+(.+?)\z/)
    required = $1

    if @create_user
      @create_user.slice!(/\s+REQUIRE\s+(\S+(?:\s+'[^']+')?)(?:\s+WITH\s+(.+))?\s+PASSWORD\s+.+\z/)
      required = $1
      resource_option = $2

      if resource_option
        @parsed[:with] ||= ''
        @parsed[:with] << ' ' << resource_option.strip
        @parsed[:with].strip!
      end
    end

    if required && required != 'NONE'
      @parsed[:require] = required.strip
    end
  end

  def parse_identified
    @stmt.slice!(/\s+IDENTIFIED BY\s+(.+?)\z/)
    identified = $1

    if @create_user
      @create_user.slice!(/\s+IDENTIFIED\s+WITH\s+'[^']+'\s+AS\s+('[^']+')/)
      identified = $1
      identified = "PASSWORD #{identified}" if identified
    end

    if identified
      @parsed[:identified] = identified.strip
    end
  end

  def parse_main
    md = /\AGRANT\s+(.+?)\s+ON\s+(.+?)\s+TO\s+'(.*)'@'(.+)'\z/.match(@stmt.gsub('`', '\''))
    privs, object, user, host = md.captures
    @parsed[:privs] = parse_privs(privs.strip)
    @parsed[:object] = object.gsub('\'', '').strip
    @parsed[:user] = user
    @parsed[:host] = host
  end

  def parse_privs(privs)
    privs << ','
    priv_list = []

    while priv = privs.slice!(/\A[^,(]+(?:\([^)]+\))?\s*,\s*/)
      priv_list << priv.strip.sub(/,\z/, '').strip
    end

    priv_list
  end
end
