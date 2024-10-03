# frozen_string_literal: true

require_relative './api_client'
require_relative './exceptions'

module Hubspot
  # Enumerable class for handling paged data from the API
  class PagedBatch < ApiClient
    include Enumerable

    MAX_LIMIT = 100 # HubSpot max items per page

    # customised inspect
    def inspect
      "#<#{self.class.name} " \
      "@url=#{@url.inspect}, " \
      "@params=#{@params.inspect}, " \
      "@resource_class=#{@resource_class.inspect}, " \
      "@object_ids_count=#{@object_ids.size}>"
    end

    # rubocop:disable Lint/MissingSuper
    def initialize(url:, params: {}, resource_class: nil, object_ids: [])
      @url = url
      @params = params
      @resource_class = resource_class
      @object_ids = object_ids
    end
    # rubocop:enable Lint/MissingSuper

    def each_page
      @object_ids.each_slice(MAX_LIMIT) do |ids|
        response = fetch_page(ids)
        mapped_results = process_results(response)
        yield mapped_results unless mapped_results.empty?
      end
    end

    def all
      results = []
      each_page do |page|
        results.concat(page)
      end
      results
    end

    def each(&block)
      each_page do |page|
        page.each(&block)
      end
    end

    private

    def fetch_page(object_ids)
      params_with_ids = @params.dup
      params_with_ids[:inputs] = object_ids.map { |id| { id: id } }

      response = self.class.post(@url, body: params_with_ids.to_json)

      handle_response(response)
    end

    def process_results(response)
      results = response['results'] || []
      return results unless @resource_class

      results.map { |result| @resource_class.new(result) }
    end
  end
end
