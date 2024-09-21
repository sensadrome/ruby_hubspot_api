# frozen_string_literal: true

require_relative 'hubspot/config'

# Main Hubspot module
module Hubspot
  class << self
    attr_writer :config

    # Ensure we always have a default config, even if configure isn't called
    def config
      @config ||= Config.new
    end

    def configure
      yield(config) if block_given?
    end
  end
end
