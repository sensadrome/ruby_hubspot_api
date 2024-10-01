# frozen_string_literal: true

# HubSpot API Client
# Handles all HTTP interactions with the HubSpot API.
# It manages GET, POST, PATCH, and DELETE requests.
module Hubspot
  # All interations with the Hubspot API happen here...
  class ApiClient
    MAX_RETRIES = 3
    RETRY_WAIT_TIME = 1 # seconds

    include HTTParty
    base_uri 'https://api.hubapi.com'

    headers 'Content-Type' => 'application/json'

    def handle_response(response)
      self.class.handle_response(response)
    end

    class << self
      def get(url, options = {})
        ensure_configuration!

        if options[:query] && options[:query][:properties].is_a?(Array)
          options[:query][:properties] = options[:query][:properties].join(',')
        end

        start_time = Time.now
        response = super(url, options)

        request = HTTParty::Request.new(Net::HTTP::Get, url, options)
        log_request(:get, request.uri.to_s, response, start_time)
        response
      end

      def post(url, options = {})
        ensure_configuration!
        start_time = Time.now
        response = super(url, options)
        log_request(:post, url, response, start_time, options)
        response
      end

      def patch(url, options = {})
        ensure_configuration!
        start_time = Time.now
        response = super(url, options)
        log_request(:patch, url, response, start_time, options)
        response
      end

      def delete(url, options = {})
        ensure_configuration!
        start_time = Time.now
        response = super(url, options)
        log_request(:delete, url, response, start_time)
        response
      end

      def log_request(http_method, url, response, start_time, extra = nil)
        d = Time.now - start_time
        Hubspot.logger.info("#{http_method.to_s.upcase} #{url} took #{d.round(2)}s with status #{response.code}")
        return unless Hubspot.logger.debug?

        Hubspot.logger.debug("Request body: #{extra}") if extra
        Hubspot.logger.debug("Response body: #{response.body}")
      end

      def handle_response(response, retries = 0)
        case response.code
        when 200..299
          response.parsed_response
        when 429
          handle_rate_limit(response, retries)
        else
          log_and_raise_error(response)
        end
      end

      private

      def handle_rate_limit(response, retries)
        if retries < MAX_RETRIES
          retry_after = response.headers['Retry-After']&.to_i || RETRY_WAIT_TIME
          Hubspot.logger.warn("Rate limit hit. Retrying in #{retry_after} seconds...")
          sleep(retry_after)
          retry_request(response.request, retries + 1)
        else
          Hubspot.logger.error('Exceeded maximum retries for rate-limited request.')
          raise Hubspot.error_from_response(response)
        end
      end

      def retry_request(request, retries)
        # Re-issues the original request using the retry logic
        http_method = request.http_method::METHOD.downcase # Use the METHOD constant to get the method string
        response = HTTParty.send(http_method, request.uri, request.options)
        handle_response(response, retries)
      end

      def log_and_raise_error(response)
        Hubspot.logger.error("API Error: #{response.code} - #{response.body}")
        raise Hubspot.error_from_response(response)
      end

      def ensure_configuration!
        raise NotConfiguredError, 'Hubspot API not configured' unless Hubspot.configured?
      end
    end
  end
end
