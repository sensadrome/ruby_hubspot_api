# frozen_string_literal: true

require_relative 'hubspot/config'

# Main Hubspot module
module Hubspot
  class << self
    extend Forwardable

    # Delegate logger to config.logger
    def_delegator :config, :logger

    attr_writer :config

    def config
      @config ||= Config.new
    end

    def configure
      yield(config) if block_given?
      set_client_headers if config.access_token
      set_request_timeouts
      config.apply_log_level
    end

    def configured?
      true unless @config.nil?
    end

    private

    # Set Authorization header on all the resource classes when access_token is configured
    def set_client_headers
      api_classes = ObjectSpace.each_object(Class).select do |klass|
        klass < Hubspot::ApiClient && !klass.singleton_class?
      end

      api_classes.each do |subclass|
        subclass.headers 'Authorization' => "Bearer #{config.access_token}"
      end
    end

    def set_request_timeouts
      config.timeout && Hubspot::ApiClient.default_timeout(config.timeout)
      timeouts = %i[open_timeout read_timeout]
      timeouts << :write_timeout if RUBY_VERSION >= '2.6'

      timeouts.each do |t|
        timeout = config.send(t)
        next unless timeout

        Hubspot::ApiClient.send(t, timeout)
      end
    end
  end
end
