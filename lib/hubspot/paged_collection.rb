# frozen_string_literal: true

require 'json'
require_relative './api_client'
require_relative './exceptions'
require_relative './resource_filter'

module Hubspot
  # Enumerable class for handling paged data from the API
  class PagedCollection < ApiClient
    include Enumerable
    include ResourceFilter::FilterGroupMethods

    MAX_LIMIT = 200 # HubSpot max items per page

    # rubocop:disable Lint/MissingSuper
    def initialize(url:, params: {}, resource_class: nil, method: :get, results_param: 'results')
      @url = url
      @params = params
      @resource_class = resource_class
      @method = method.to_sym
      @results_param = results_param
    end
    # rubocop:enable Lint/MissingSuper

    def total
      @total ||= determine_total
    end

    def each_page
      offset = nil
      loop do
        response = fetch_page(offset)
        @total = response['total'] if response['total']
        mapped_results = process_results(response)
        yield mapped_results unless mapped_results.empty?
        sleep wait_between_pages
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
    # rubocop:disable Metrics/MethodLength
    def first(limit = 1)
      resources = []
      remaining = limit

      original_limit = @params.delete(:limit)
      # Modify @params directly to set the limit
      @params[:limit] = [remaining, MAX_LIMIT].min

      # loop through pages in case limit is more than the max limit
      each_page do |page|
        resources.concat(page)
        remaining -= page.size
        break if remaining <= 0
      end

      @params[:limit] = original_limit
      limit == 1 ? resources.first : resources.first(limit)
    end
    # rubocop:enable Metrics/MethodLength

    def each(&block)
      each_page do |page|
        page.each(&block)
      end
    end

    def where(filters = {})
      dup.where!(filters)
    end

    def where!(filters = {})
      # Build new filter groups from the provided filters
      new_filter_groups = build_filter_groups(filters)

      # Merge new filters into the existing params structure
      if @params[:filterGroups]&.any?
        @params[:filterGroups][0][:filters].concat(new_filter_groups[0][:filters])
      else
        @params[:filterGroups] = new_filter_groups
      end

      self # Returning self for method chaining if needed
    end

    def select(*properties)
      unless properties.blank?
        @params ||= {}
        @params[:properties] ||= []
        @params[:properties].concat(properties.flatten)
      end

      self
    end

    private

    def determine_total
      # We only get a response['total'] for the search endpoint
      raise NotImplementedError, 'Total only available for search requests' unless search_request?

      # if we don't already know the total we will make a single request and minimise the response
      # size by asking for just one property and one record.

      # store the current properties
      original_properties = @params.delete(:properties)

      # just request hs_object_id
      @params[:properties] = ['hs_object_id']

      # dummy request. @total will be set during the each_page evaluation
      _first_page = first

      # restore the original properties
      @params[:properties] = original_properties

      # return the now set total
      @total
    end

    def search_request?
      @url.include?('/search')
    end

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

    def wait_between_pages
      return 0.2 if search_request?

      0
    end

    def process_results(response)
      results = response[@results_param] || []
      return results unless @resource_class

      results.map { |result| @resource_class.new(result) }
    end
  end
end
