# frozen_string_literal: true

require 'delegate'

module Hubspot
  # exactly the same as a parsed_response but with the status code preserved
  class BatchResponse < SimpleDelegator
    attr_reader :status_code

    def initialize(status_code, parsed_response)
      @status_code = status_code
      super(parsed_response) # Delegate to the parsed response object
    end

    # Check if all responses were successful (status 200)
    def all_successful?
      @status_code == 200
    end

    # Check if some responses succeeded and some failed (status 207)
    def partial_success?
      @status_code == 207
    end
  end

  # Class to handle batch updates of resources
  # rubocop:disable Metrics/ClassLength
  class Batch < ApiClient
    attr_accessor :id_property, :resources, :responses

    CONTACT_LIMIT = 10
    DEFAULT_LIMIT = 100

    # :nocov:
    def inspect
      "#<#{self.class.name} " \
      "@resource_count=#{@resources.size}, " \
      "@id_property=#{@id_property.inspect}, " \
      "@resource_type=#{@resources.first&.resource_name}, " \
      "@responses_count=#{@responses.size}>"
    end
    # :nocov:

    # rubocop:disable Lint/MissingSuper
    def initialize(resources = [], id_property: 'id', resource_matcher: nil)
      validate_resource_matcher(resource_matcher)

      @resources = []
      @id_property = id_property # Set id_property for the batch (default: 'id')
      @responses = []            # Store multiple BatchResponse objects here
      resources.each { |resource| add_resource(resource) }
    end
    # rubocop:enable Lint/MissingSuper

    # batch create from the resources
    def create
      save(action: 'create')
    end

    def update
      # validate_update_conditions
      save(action: 'update')
    end

    # Upsert method that calls save with upsert action
    def upsert(resource_matcher: nil)
      validate_resource_matcher(resource_matcher)

      validate_upsert_conditions
      save(action: 'upsert')
    end

    def validate_resource_matcher(resource_matcher)
      return if resource_matcher.blank?

      unless resource_matcher.is_a?(Proc) && resource_matcher.arity == 2
        raise ArgumentError, 'resource_matcher must be a proc that accepts exactly 2 arguments'
      end

      @resource_matcher = resource_matcher
    end

    # Archive method
    def archive
      save(action: 'archive')
    end

    # Check if all responses were successful
    def all_successful?
      @responses.all?(&:all_successful?)
    end

    # Check if some responses were successful and others failed
    def partial_success?
      @responses.any?(&:partial_success?) && @responses.none?(&:all_successful?)
    end

    # Check if any responses failed
    def any_failed?
      @responses.any? { |response| !response.all_successful? && !response.partial_success? }
    end

    def add_resource(resource)
      if @resources.any?
        if @resources.first.resource_name != resource.resource_name
          raise ArgumentError, 'All resources in a batch must be of the same type'
        end
      else
        add_resource_method(resource.resource_name)
      end

      @resources << resource
    end

    def any_changes?
      @resources.any?(&:changes?)
    end

    private

    def add_resource_method(resource_name)
      self.class.class_eval do
        alias_method resource_name.to_sym, :resources
      end
    end

    # rubocop:disable Metrics/MethodLength
    def save(action: 'update')
      @action = action
      resource_type = check_single_resource_type
      inputs = gather_inputs

      return false if inputs.empty? # Guard clause

      # Perform the batch updates in chunks based on the resource type's limit
      batch_limit = batch_size_limit(resource_type)
      inputs.each_slice(batch_limit) do |batch_inputs|
        response = batch_request(resource_type, batch_inputs, action)
        @responses << response
      end

      process_responses unless @action == 'archive'

      # Check if any responses failed
      !any_failed?
    end
    # rubocop:enable Metrics/MethodLength

    def check_single_resource_type
      raise 'Batch is empty' if @resources.empty?

      @resources.first.resource_name
    end

    # Gather all the changes, ensuring each resource has an id and changes
    def gather_inputs
      return gather_archive_inputs if @action == 'archive'

      @resources.map do |resource|
        next if resource.changes.empty?

        {
          # Dynamically get the ID based on the batch's id_property
          id: resource.public_send(@id_property),
          # Use the helper method to decide whether to include idProperty
          idProperty: determine_id_property,
          # Gather the changes for the resource
          properties: resource.changes
        }.compact   # Removes nil keys
      end.compact   # Removes nil entries
    end

    # Gather inputs for the archive operation
    def gather_archive_inputs
      @resources.map do |resource|
        {
          id: resource.public_send(@id_property),   # Use the ID or the custom property
          idProperty: determine_id_property         # Include idProperty if it's not "id"
        }.compact
      end.compact
    end

    # Only include idProperty if it's not "id"
    def determine_id_property
      @id_property == 'id' ? nil : @id_property
    end

    # Perform batch request based on the provided action (upsert, update, create, or archive)
    def batch_request(type, inputs, action)
      response = self.class.post("/crm/v3/objects/#{type}/batch/#{action}",
                                 body: { inputs: inputs }.to_json)
      BatchResponse.new(response.code, handle_response(response))
    end

    # Validation for upsert conditions
    def validate_upsert_conditions
      raise ArgumentError, "id_property cannot be 'id' for upsert" if @id_property == 'id'

      # check if there are any resources without a value from the id_property
      return unless @resources.any? { |resource| resource.public_send(id_property).blank? }

      raise ArgumentError,
            "All resources must have a non-blank value for #{@id_property} to perform upsert"
    end

    # Return the appropriate batch size limit for the resource type
    def batch_size_limit(resource_type)
      resource_type == 'contacts' ? CONTACT_LIMIT : DEFAULT_LIMIT
    end

    # Process responses from the batch API call
    def process_responses
      # TODO: issue a warning if the id_property is email and the action is upsert*
      # people may have more than one email address abd Hubspot views that as one record
      @responses.each do |response|
        next unless response['results']

        process_results(response['results'])
      end
    end

    # Process each result and update the resource accordingly
    def process_results(results)
      results.each do |result|
        resource = find_resource_from_result(result)
        next unless resource

        # Set the ID on the resource directly
        resource.id = result['id'].to_i if result['id']

        # Update the resource properties
        update_resource_properties(resource, result['properties'])

        # Update metadata like updatedAt
        update_metadata(resource, result['updatedAt'])
      end
    end

    def find_resource_from_result(result)
      action_method = method_for_action
      send(action_method, result) if action_method
    end

    def method_for_action
      {
        'create' => :find_resource_for_created_result,
        'update' => :find_resource_from_updated_result,
        'upsert' => :find_resource_from_upserted_result
      }[@action]
    end

    def find_resource_for_created_result(result)
      properties = result['properties']

      @resources.reject(&:persisted?).find do |resource|
        next unless resource.changes.any?

        resource.changes.all? { |key, value| properties[key.to_s] == value }
      end
    end

    def find_resource_from_updated_result(result)
      resource_id = id_property == 'id' ? result['id'].to_i : result.dig('properties', id_property)
      find_resource_from_id(resource_id)
    end

    def find_resource_from_id(resource_id)
      return find_resource_from_id_property(resource_id) unless @id_property == 'id'

      @resources.find { |resource| resource.id == resource_id }
    end

    def find_resource_from_id_property(resource_id)
      @resources.find do |resource|
        resource.respond_to?(@id_property) && resource.public_send(@id_property) == resource_id
      end
    end

    def find_resource_from_upserted_result(result)
      # if this was inserted then match on all the fields
      return find_resource_for_created_result(result['properties']) if result['new']

      # call the custom resource matcher if specified
      if @resource_matcher
        @resources.find { |resource| @resource_matcher.call(resource, result) }
      else
        find_resource_from_updated_result(result)
      end
    end

    def update_resource_properties(resource, properties)
      properties.each do |key, value|
        if resource.changes[key]
          resource.properties[key] = value
          resource.changes.delete(key)
        end
      end
    end

    def update_metadata(resource, updated_at)
      resource.metadata['updatedAt'] = updated_at if updated_at
    end

    class << self
      def read(object_class, object_ids = [], id_property: 'id')
        unless object_class < Hubspot::Resource
          raise ArgumentError, 'Must be a valid Hubspot resource class'
        end

        # fetch all the matching resources with paging handled
        resources = object_class.batch_read(object_ids, id_property: id_property).all

        # return instance of Hubspot::Batch with the resources set
        new(resources, id_property: id_property)
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
