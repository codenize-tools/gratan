require 'csv'

class Gratan::Identifier::CSV
  include Gratan::Logger::Helper

  def initialize(path, options = {})
    @options = options
    @passwords = {}

    CSV.foreach(path) do |row|
      @passwords[row[0]] = row[1]
    end
  end

  def identify(user, host)
    user_host = "#{user}@#{host}"
    password = @passwords[user_host]

    unless password
      log(:warn, "password for `#{user_host}` can not be found", :yellow)
    end

    password
  end
end
