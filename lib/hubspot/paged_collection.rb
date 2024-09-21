# frozen_string_literal: true

require_relative './api_client'
require_relative './exceptions'

module Hubspot
  # Enumerable class for handling paged data from the API
  class PagedCollection < ApiClient
    include Enumerable

    RATE_LIMIT_STATUS = 429
    MAX_RETRIES = 3
    RETRY_WAIT_TIME = 3
    MAX_LIMIT = 100 # HubSpot max items per page

    # rubocop:disable Lint/MissingSuper
    def initialize(url:, params: {}, resource_class: nil, method: :get)
      @url = url
      @params = params
      @resource_class = resource_class
      @method = method.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def each_page
      offset = nil
      loop do
        response = fetch_page(offset)
        results = response['results'] || []
        mapped_results = @resource_class ? results.map { |result| @resource_class.new(result) } : results
        yield mapped_results unless mapped_results.empty?
        offset = response.dig('paging', 'next', 'after')
        break unless offset
      end
    end

    def all
      results = []
      each_page do |page|
        results.concat(page)
      end
      results
    end

    # Enhanced first(n) method with proper @params modification
    def first(limit = 1)
      results = []
      remaining = limit

      # Modify @params directly to set the limit
      @params[:limit] = [remaining, MAX_LIMIT].min

      each_page do |page|
        results.concat(page)
        remaining -= page.size
        break if remaining <= 0
      end

      results.first(limit)
    end

    def each(&block)
      each_page do |page|
        page.each(&block)
      end
    end

    private

    def fetch_page(offset, attempt = 1, params_override = @params)
      params_with_offset = params_override.merge(after: offset)
      response = self.class.send(@method, @url, body: params_with_offset.to_json)

      if response.code == RATE_LIMIT_STATUS
        handle_rate_limit(response, offset, attempt, params_override)
      else
        handle_response(response)
      end
    end

    def handle_rate_limit(response, offset, attempt, params_override)
      raise Hubspot::RateLimitExceeded, response if attempt > MAX_RETRIES

      retry_after = response.headers['Retry-After']&.to_i || RETRY_WAIT_TIME
      sleep(retry_after)
      fetch_page(offset, attempt + 1, params_override)
    end
  end
end
