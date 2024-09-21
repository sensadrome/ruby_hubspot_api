# frozen_string_literal: true

require_relative './api_client'

module Hubspot
  # rubocop:disable Metrics/ClassLength
  # Hubspot::Resource class
  class Resource < ApiClient
    # Allow read/write access to properties and metadata
    attr_accessor :id, :properties, :changes, :metadata

    class << self
      # Find a resource by ID and return an instance of the class
      def find(id)
        response = get("/crm/v3/objects/#{resource_name}/#{id}")
        instantiate_from_response(response)
      end

      # Create a new resource
      def create(params)
        response = post("/crm/v3/objects/#{resource_name}", body: { properties: params }.to_json)
        instantiate_from_response(response)
      end

      def update(id, params)
        response = patch("/crm/v3/objects/#{resource_name}/#{id}", body: { properties: params }.to_json)
        raise Hubspot.error_from_response(response) unless response.success?

        true
      end

      def archive(id)
        response = delete("/crm/v3/objects/#{resource_name}/#{id}")
        raise Hubspot.error_from_response(response) unless response.success?

        true
      end

      def list(params = {})
        PagedCollection.new(
          url: "/crm/v3/objects/#{resource_name}",
          params: params,
          resource_class: self
        )
      end

      # Get the complete list of fields (properties) for the object
      def full_property_list
        all_properties.each_with_object({}) do |property, hash|
          hash[property['name']] = property['description'] || property['label']
        end
      end

      # Get the list of non-hubspot fields (properties) for the object
      def custom_property_list
        custom_properties.each_with_object({}) do |property, hash|
          hash[property['name']] = property['description'] || property['label']
        end
      end

      def all_properties
        @all_properties ||= begin
          response = get("/crm/v3/properties/#{resource_name}")
          handle_response(response)['results']
        end
      end

      def custom_properties
        all_properties.reject { |property| property['hubspotDefined'] }
      end

      private

      # Define the resource name based on the class
      def resource_name
        name = self.name.split('::').last.downcase
        if name.end_with?('y')
          name.gsub(/y$/, 'ies') # Company -> companies
        else
          "#{name}s" # Contact -> contacts, Deal -> deals
        end
      end

      # Instantiate a single resource object from the response
      def instantiate_from_response(response)
        data = handle_response(response)
        new(data) # Passing full response data to initialize
      end
    end

    # rubocop:disable Ling/MissingSuper
    def initialize(data = {})
      @id = data['id'] ? data['id'].to_i : nil

      # data sent as as attributes from the API fetch
      if @id
        @properties = data['properties'] || {}
        @metadata = data.reject { |key, _| key == 'properties' } # Store non-properties data in @metadata
        @changes = {} # Initialize @changes to track modifications

      # or initialising a new object
      else
        @properties = {}
        @changes = data.transform_keys(&:to_s)
        @metadata = {}
      end
    end
    # rubocop:enable Ling/MissingSuper

    # Instance methods for update (or save)
    def save
      if persisted?
        self.class.update(@id, @changes).tap do |result|
          return false unless result

          @properties.merge!(@changes)
          @changes = {}
        end
      else
        create_new
      end
    end

    def persisted?
      @id ? true : false
    end

    # Update the resource
    def update(params)
      raise 'Not able to update as not persisted' unless persisted?

      params.each do |key, value|
        send("#{key}=", value) # This will trigger the @changes tracking via method_missing
      end

      save
    end

    def delete
      self.class.archive(id)
    end
    alias archive delete

    # rubocop:disable Metrics/MethodLength
    # Handle dynamic getter and setter methods with method_missing
    def method_missing(method, *args)
      method_name = method.to_s

      # Handle setters
      if method_name.end_with?('=')
        attribute = method_name.chomp('=')
        new_value = args.first

        # Track changes only if the value has actually changed
        if @properties[attribute] != new_value
          @changes[attribute] = new_value
        else
          @changes.delete(attribute) # Remove from changes if it reverts to the original value
        end

        return new_value
      # Handle getters
      else
        return @changes[method_name] if @changes.key?(method_name)
        return @properties[method_name] if @properties.key?(method_name)
      end

      # Fallback if the method or attribute is not found
      super
    end
    # rubocop:enable Metrics/MethodLength

    # Ensure respond_to_missing? is properly overridden
    def respond_to_missing?(method_name, include_private = false)
      property_name = method_name.to_s.chomp('=')
      @properties.key?(property_name) || @changes.key?(property_name) || super
    end

    private

    # Create a new resource
    def create_new
      created_resource = self.class.create(@changes)
      @id = created_resource.id
      @id ? true : false
    end
  end
  # rubocop:enable Metrics/ClassLength
end
