class Gratan::GrantParser
  def initialize(stmt)
    @stmt = stmt.strip
    @parsed = {}
  end

  def self.parse(stmt)
    parser = self.new(stmt)
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

    if required
      @parsed[:require] = required.strip
    end
  end

  def parse_identified
    @stmt.slice!(/\s+IDENTIFIED BY\s+(.+?)\z/)
    identified = $1

    if identified
      @parsed[:identified] = identified.strip
    end
  end

  def parse_main
    md = /\AGRANT\s+(.+?)\s+ON\s+(.+?)\s+TO\s+'(.*)'@'(.+)'\z/.match(@stmt)
    privs, object, user, host = md.captures
    @parsed[:privs] = parse_privs(privs.strip)
    @parsed[:object] = object.gsub('`', '').strip
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
