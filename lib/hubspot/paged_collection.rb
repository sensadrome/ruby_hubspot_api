# frozen_string_literal: true

require 'json'
require_relative './api_client'
require_relative './exceptions'

module Hubspot
  # Enumerable class for handling paged data from the API
  class PagedCollection < ApiClient
    include Enumerable

    MAX_LIMIT = 100 # HubSpot max items per page

    def initialize(url:, params: {}, resource_class: nil, method: :get)
      @url = url
      @params = params
      @resource_class = resource_class
      @method = method.to_sym
    end

    def each_page
      offset = nil
      loop do
        response = fetch_page(offset)
        mapped_results = process_results(response)
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

    # Override Enumerable's first method so as not to have to call each (via all)
    def first(limit = 1)
      resources = []
      remaining = limit

      # Modify @params directly to set the limit
      @params[:limit] = [remaining, MAX_LIMIT].min

      # loop through pages in case limit is more than the max limit
      each_page do |page|
        resources.concat(page)
        remaining -= page.size
        break if remaining <= 0
      end

      limit == 1 ? resources.first : resources.first(limit)
    end

    def each(&block)
      each_page do |page|
        page.each(&block)
      end
    end

    private

    def fetch_page(offset)
      params_with_offset = @params.dup
      params_with_offset.merge!(after: offset) if offset

      # Handle different HTTP methods
      response = fetch_response_by_method(params_with_offset)

      handle_response(response)
    end

    def fetch_response_by_method(params = {})
      case @method
      when :get
        self.class.send(@method, @url, query: params)
      else
        self.class.send(@method, @url, body: params.to_json)
      end
    end

    def process_results(response)
      results = response['results'] || []
      return results unless @resource_class

      results.map { |result| @resource_class.new(result) }
    end
  end
end
