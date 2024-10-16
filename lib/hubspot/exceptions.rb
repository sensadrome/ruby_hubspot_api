# frozen_string_literal: true

# The main hubspot module
module Hubspot
  # define the Hubspot specific error classes
  class RequestError < StandardError
    attr_accessor :response

    def initialize(response, message = nil)
      if !message && response.respond_to?(:parsed_response)
        message = response.parsed_response['message']
      end
      message += "\n" if message
      me = super("#{message}Response body: #{response.body}",)
      me.response = response
    end
  end

  class NotFoundError < RequestError; end
  class OauthScopeError < RequestError; end
  class RateLimitExceededError < RequestError; end
  class NotConfiguredError < StandardError; end
  class ArgumentError < StandardError; end
  class NothingToDoError < StandardError; end
  class NotImplementedError < StandardError; end

  class << self
    def error_from_response(response)
      return NotFoundError.new(response) if response.not_found?
      return RateLimitExceededError.new(response) if response.code == 429

      case response.body
      when /MISSING_SCOPES/, /You do not have permissions/i
        OauthScopeError.new(response, 'Private app missing required scopes')
      else
        RequestError.new(response)
      end
    end
  end
end
