class Gratan::Exporter
  def self.export(driver, options = {}, &block)
    self.new(driver, options).export(&block)
  end

  def initialize(driver, options = {})
    @driver = driver
    @options = options
  end

  def export
    grants = []

    @driver.each_user do |user, host|
      next if user =~ @options[:ignore_user]

      if @options[:target_user]
        next unless user =~ @options[:target_user]
      end

      if @options[:use_show_create_user]
        create_user = @driver.show_create_user(user, host)
      end

      @driver.show_grants(user, host) do |stmt|
        grants << Gratan::GrantParser.parse(stmt, create_user)
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
      next if object =~ @options[:ignore_object]
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
