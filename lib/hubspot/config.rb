# frozen_string_literal: true

module Hubspot
  # To hold Hubspot configuration
  class Config
    attr_accessor :access_token, :portal_id, :client_secret

    def initialize
      @access_token = nil
      @portal_id = nil
      @client_secret = nil
    end
  end
end
