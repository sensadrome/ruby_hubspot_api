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
  class Batch < ApiClient
    attr_accessor :id_property, :resources, :responses

    CONTACT_LIMIT = 10
    DEFAULT_LIMIT = 100

    # rubocop:disable Lint/MissingSuper
    def initialize(resources = [], id_property: 'id')
      @resources = []
      @id_property = id_property # Set id_property for the batch (default: 'id')
      @responses = []            # Store multiple BatchResponse objects here
      resources.each { |resource| add_resource(resource) }
    end
    # rubocop:enable Lint/MissingSuper

    # Save the batch and return true/false based on whether it was successful
    def save(endpoint: 'update')
      resource_type = check_single_resource_type
      inputs = gather_inputs

      return false if inputs.empty? # Guard clause

      # Perform the batch updates in chunks based on the resource type's limit
      batch_limit = batch_size_limit(resource_type)
      inputs.each_slice(batch_limit) do |batch_inputs|
        response = batch_request(resource_type, batch_inputs, endpoint)
        @responses << response
      end

      # Check if any responses failed
      !any_failed?
    end

    # Upsert method that calls save with upsert endpoint
    def upsert
      validate_upsert_conditions
      save(endpoint: 'upsert')
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

    private

    def add_resource(resource)
      if @resources.any? && @resources.first.resource_name != resource.resource_name
        raise ArgumentError, 'All resources in a batch must be of the same type'
      end

      @resources << resource
    end

    def check_single_resource_type
      raise 'Batch is empty' if @resources.empty?

      @resources.first.resource_name
    end

    # Gather all the changes, ensuring each resource has an id and changes
    def gather_inputs
      @resources.map do |resource|
        next if resource.changes.empty?

        {
          id: resource.public_send(@id_property),   # Dynamically get the ID based on the batch's id_property
          idProperty: determine_id_property,        # Use the helper method to decide whether to include idProperty
          properties: resource.changes              # Gather the changes for the resource
        }.compact   # Removes nil keys
      end.compact   # Removes nil entries
    end

    # Only include idProperty if it's not "id"
    def determine_id_property
      @id_property == 'id' ? nil : @id_property
    end

    # Perform batch request based on the provided endpoint (upsert or update)
    def batch_request(type, inputs, endpoint)
      response = post("/crm/v3/objects/#{type}/batch/#{endpoint}", body: { inputs: inputs })
      BatchResponse.new(response.code, handle_response(response))
    end

    # Validation for upsert conditions
    def validate_upsert_conditions
      raise ArgumentError, "id_property cannot be 'id' for upsert" if @id_property == 'id'

      if @resources.any? { |resource| resource.public_send(id_property).blank? }
        raise ArgumentError, "All resources must have a non-blank value for #{@id_property} to perform upsert"
      end
    end

    # Return the appropriate batch size limit for the resource type
    def batch_size_limit(resource_type)
      resource_type == 'contacts' ? CONTACT_LIMIT : DEFAULT_LIMIT
    end
  end
end
