class Gratan::Exporter
  def self.export(driver, options = {})
    self.new(driver, options).export
  end

  def initialize(driver, options = {})
    @driver = driver
    @options = options
  end

  def export
    grants = []

    @driver.each_user do |user, host|
      @driver.show_grants(user, host) do |stmt|
        grants << Gratan::GrantParser.parse(stmt)
      end
    end

    pack(grants)
  end

  private

  def pack(grants)
    packed = {}

    grants.each do |grant|
      user = grant.delete(:user)
      host = grant.delete(:host)
      user_host = [user, host]
      object = grant.delete(:object)
      identified = grant.delete(:identified)
      required = grant.delete(:require)

      packed[user_host] ||= {:objects => {}, :options => {}}
      packed[user_host][:objects][object] = grant
      packed[user_host][:options][:required] = required if required

      if @options[:with_identifier] and identified
        packed[user_host][:options][:identified] = identified
      end
    end

    packed
  end
end
