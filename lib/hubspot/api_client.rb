# frozen_string_literal: true

module Hubspot
  # All interations with the Hubspot API happen here...
  class ApiClient
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
        log_request(:post, url, response, start_time)
        response
      end

      def patch(url, options = {})
        ensure_configuration!
        start_time = Time.now
        response = super(url, options)
        log_request(:patch, url, response, start_time)
        response
      end

      def delete(url, options = {})
        ensure_configuration!
        start_time = Time.now
        response = super(url, options)
        log_request(:delete, url, response, start_time)
        response
      end

      def log_request(http_method, url, response, start_time)
        d = Time.now - start_time
        Hubspot.logger.info("#{http_method.to_s.upcase} #{url} took #{d.round(2)}s with status #{response.code}")
        Hubspot.logger.debug("Response body: #{response.body}") if Hubspot.logger.debug?
      end

      def handle_response(response)
        if response.success?
          response.parsed_response
        else
          Hubspot.logger.error("API Error: #{response.code} - #{response.body}")
          raise Hubspot.error_from_response(response)
        end
      end

      private

      def ensure_configuration!
        raise NotConfiguredError, 'Hubspot API not configured' unless Hubspot.configured?
      end
    end
  end
end
