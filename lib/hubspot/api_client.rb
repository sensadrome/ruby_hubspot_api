# frozen_string_literal: true

require_relative './exceptions'

module Hubspot
  # For handling communication with the Hubspot API
  class ApiClient
    include HTTParty
    base_uri 'https://api.hubapi.com'

    # Default headers (Authorization is set by the Hubspot module)
    headers 'Content-Type' => 'application/json'
  end
end
