# frozen_string_literal: true

module Hubspot
  # To hold Hubspot configuration
  class Config
    attr_accessor :access_token, :portal_id, :client_secret, :logger, :log_level,
                  :timeout, :open_timeout, :read_timeout, :write_timeout

    def initialize
      @access_token = nil
      @portal_id = nil
      @client_secret = nil
      @logger = initialize_logger
      @log_level = determine_log_level
      apply_log_level
    end

    # Apply the log level to the logger
    def apply_log_level
      @logger.level = @log_level
    end

    private

    # Initialize the default logger
    def initialize_logger
      Logger.new($stdout)
    end

    # Map string values from environment variables to Logger constants
    def determine_log_level
      level = env_log_level.upcase

      if Logger.const_defined?(level)
        Logger.const_get(level)
      else
        Logger::INFO # Default to INFO if unrecognized
      end
    end

    def env_log_level
      ENV['HUBSPOT_LOG_LEVEL'] || default_log_level
    end

    # Set the default log level based on environment
    def default_log_level
      if defined?(Rails) && Rails.env.test?
        'FATAL'  # Default to FATAL in test environments
      else
        'INFO'   # Default to INFO in normal usage
      end
    end
  end
end
