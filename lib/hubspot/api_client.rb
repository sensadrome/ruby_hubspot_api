# frozen_string_literal: true

require_relative './exceptions'

module Hubspot
  # For handling communication with the Hubspot API
  class ApiClient
    include HTTParty
    base_uri 'https://api.hubapi.com'

    # Default headers (Authorization is set by the Hubspot module)
    headers 'Content-Type' => 'application/json'

    def handle_response(response)
      self.class.handle_response(response)
    end

    class << self
      # Process the response and return the parsed data
      def handle_response(response)
        raise Hubspot.error_from_response(response) unless response.success?

        response.parsed_response
      end
    end
  end
end
