# frozen_string_literal: true

# The main hubspot module
module Hubspot
  # define the Hubspot specific error classes
  class RequestError < StandardError
    attr_accessor :response

    def initialize(response, message = nil)
      message = response.parsed_response['message'] if !message && response.respond_to?(:parsed_response)
      message += "\n" if message
      me = super("#{message}Response body: #{response.body}",)
      me.response = response
    end
  end

  class NotFoundError < RequestError; end
  class OauthScopeError < RequestError; end
  class RateLimitExceeded < RequestError; end

  class << self
    def error_from_response(response)
      return NotFoundError.new(response) if response.not_found?

      case response.body
      when /MISSING_SCOPES/
        OauthScopeError.new(response, 'Private app missing required scopes')
      else
        RequestError.new(response)
      end
    end
  end
end
