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
    end

    def configured?
      return true unless @config.nil?
    end

    private

    # Set Authorization header on Hubspot::ApiClient when access_token is configured
    def set_client_headers
      Hubspot::ApiClient.headers 'Authorization' => "Bearer #{config.access_token}"
    end
  end
end
