class Gratan::Logger < ::Logger
  include Singleton

  def initialize
    super($stdout)

    self.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    self.level = Logger::INFO
  end

  def set_debug(value)
    self.level = value ? Logger::DEBUG : Logger::INFO
  end

  module Helper
    def log(level, message, options = {})
      global_options = @options || {}
      message = "#{@object_identifier}: #{message}" if @object_identifier
      message = "[#{level.to_s.upcase}] #{message}" unless level == :info

      if global_options[:dry_run] and options[:dry_run] != false
        message << ' (dry-run)' if global_options[:dry_run]
      end

      message = message.send(options[:color]) if options[:color]
      logger = global_options[:logger] || Gratan::Logger.instance
      logger.send(level, message)
    end
  end
end
