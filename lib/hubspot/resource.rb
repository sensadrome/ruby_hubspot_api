# frozen_string_literal: true

require_relative './api_client'
require_relative './paged_collection'
require_relative './paged_batch'

module Hubspot
  # rubocop:disable Metrics/ClassLength

  # HubSpot Resource Base Class
  # This class provides common functionality for interacting with HubSpot API resources such as Contacts, Companies, etc
  #
  # It supports common operations like finding, creating, updating, and deleting resources, as well as batch operations.
  #
  # This class is meant to be inherited by specific resources like `Hubspot::Contact`.
  #
  # You can access the properties of a resource instance by calling the property name as method
  #
  # Example Usage:
  #   Hubspot::Contact.find(1)
  #   contact.name # 'Luke'
  #
  #   company = Hubspot::Company.create(name: "Acme Corp")
  #   company.id.nil? # false
  #
  class Resource < ApiClient
    METADATA_FIELDS = %w[createdate hs_object_id lastmodifieddate].freeze

    # Allow read/write access to id, properties, changes and metadata

    # the id of the object in hubspot
    attr_accessor :id

    # the properties as if read from the api
    attr_accessor :properties

    # track any changes made to properties before saving etc
    attr_accessor :changes

    # any other data sent from the api about the resource
    attr_accessor :metadata

    class << self
      # Find a resource by ID and return an instance of the class
      #
      # id - [Integer] The ID (or hs_object_id) of the resource to fetch.
      #
      # Example:
      #   contact = Hubspot::Contact.find(1)
      #
      # Returns An instance of the resource.
      def find(id)
        response = get("/crm/v3/objects/#{resource_name}/#{id}")
        instantiate_from_response(response)
      end

      # Finds a resource by a given property and value.
      #
      # property - The property to search by (e.g., "email").
      # value - The value of the property to match.
      # properties - Optional list of properties to return.
      #
      # Example:
      #   properties = %w[firstname lastname email last_contacted]
      #   contact = Hubspot::Contact.find_by("email", "john@example.com", properties)
      #
      # Returns An instance of the resource.
      def find_by(property, value, properties = nil)
        params = { idProperty: property }
        params[:properties] = properties if properties.is_a?(Array)
        response = get("/crm/v3/objects/#{resource_name}/#{value}", query: params)
        instantiate_from_response(response)
      end

      # Creates a new resource with the given parameters.
      #
      # params - The properties to create the resource with.
      #
      # Example:
      #   contact = Hubspot::Contact.create(name: "John Doe", email: "john@example.com")
      #
      # Returns [Resource] The newly created resource.
      def create(params)
        response = post("/crm/v3/objects/#{resource_name}", body: { properties: params }.to_json)
        instantiate_from_response(response)
      end

      # Updates an existing resource by ID.
      #
      # id - The ID of the resource to update.
      # params - The properties to update.
      #
      # Example:
      #   contact.update(1, name: "Jane Doe")
      #
      # Returns True if the update was successful, false if not
      def update(id, params)
        response = patch("/crm/v3/objects/#{resource_name}/#{id}", body: { properties: params }.to_json)
        raise Hubspot.error_from_response(response) unless response.success?

        true
      end

      # Deletes a resource by ID.
      #
      # id - The ID of the resource to delete.
      #
      # Example:
      #   Hubspot::Contact.archive(1)
      #
      # Returns True if the deletion was successful, false if not
      def archive(id)
        response = delete("/crm/v3/objects/#{resource_name}/#{id}")
        raise Hubspot.error_from_response(response) unless response.success?

        true
      end

      # Lists all resources with optional filters and pagination.
      #
      # params - Optional parameters to filter or paginate the results.
      #
      # Example:
      #   contacts = Hubspot::Contact.list(limit: 100)
      #
      # Returns [PagedCollection] A collection of resources.
      def list(params = {})
        PagedCollection.new(
          url: "/crm/v3/objects/#{resource_name}",
          params: params,
          resource_class: self
        )
      end

      # Performs a batch read operation to retrieve multiple resources by their IDs.
      #
      # object_ids  - A list of resource IDs to fetch.
      #
      # id_property - The property to use for identifying resources (default: 'id').
      #
      #
      # Example:
      #   Hubspot::Contact.batch_read([1, 2, 3])
      #
      # Returns [PagedBatch] A paged batch of resources (call .each_page to cycle through pages from the API)
      def batch_read(object_ids = [], id_property: 'id')
        params = id_property == 'id' ? {} : { idProperty: id_property }

        PagedBatch.new(
          url: "/crm/v3/objects/#{resource_name}/batch/read",
          params: params,
          object_ids: object_ids,
          resource_class: self
        )
      end

      # Performs a batch read operation to retrieve multiple resources by their IDs
      # until there are none left
      #
      # object_ids - A list of resource IDs to fetch. [Array<Integer>]
      # id_property - The property to use for identifying resources (default: 'id').
      #
      # Example:
      #   Hubspot::Contact.batch_read([1, 2, 3])
      #
      # Returns [Hubspot::Batch] A batch of resources that can be operated on further
      def batch_read_all(object_ids = [], id_property: 'id')
        Hubspot::Batch.read(self, object_ids, id_property: id_property)
      end

      # Retrieve the complete list of properties for this resource class
      #
      # Returns [Array<Hubspot::Property>] An array of hubspot properties
      def properties
        @properties ||= begin
          response = get("/crm/v3/properties/#{resource_name}")
          handle_response(response)['results'].map { |hash| Property.new(hash) }
        end
      end

      # Retrieve the complete list of user defined properties for this resource class
      #
      # Returns [Array<Hubspot::Property>] An array of hubspot properties
      def custom_properties
        properties.reject { |property| property['hubspotDefined'] }
      end

      # Retrieve the complete list of updatable properties for this resource class
      #
      # Returns [Array<Hubspot::Property>] An array of updateable hubspot properties
      def updatable_properties
        properties.reject(&:read_only?)
      end

      # Retrieve the complete list of read-only properties for this resource class
      #
      # Returns [Array<Hubspot::Property>] An array of read-only hubspot properties
      def read_only_properties
        properties.select(&:read_only)
      end

      # Retrieve information about a specific property
      #
      # Example:
      #   property = Hubspot::Contact.property('industry_sector')
      #   values_for_select = property.options.each_with_object({}) { |prop, ps| ps[prop['value']] = prop['label'] }
      #
      # Returns [Array<Hubspot::Property>] An array of hubspot properties
      def property(property_name)
        properties.detect { |prop| prop.name == property_name }
      end

      # Simplified search interface
      OPERATOR_MAP = {
        '_contains' => 'CONTAINS_TOKEN',
        '_gt' => 'GT',
        '_lt' => 'LT',
        '_gte' => 'GTE',
        '_lte' => 'LTE',
        '_neq' => 'NEQ',
        '_in' => 'IN'
      }.freeze

      # rubocop:disable Metrics/MethodLength

      # Search for resources using a flexible query format and optional properties.
      #
      # This method allows searching for resources by passing a query in the form of a string (for full-text search)
      # or a hash with special suffixes on the keys to define different comparison operators.
      # You can also specify which properties to return and the number of results per page.
      #
      # Available suffixes for query keys (when using a hash):
      #   - `_contains`: Matches values that contain the given string.
      #   - `_gt`: Greater than comparison.
      #   - `_lt`: Less than comparison.
      #   - `_gte`: Greater than or equal to comparison.
      #   - `_lte`: Less than or equal to comparison.
      #   - `_neq`: Not equal to comparison.
      #   - `_in`: Matches any of the values in the given array.
      #
      # If no suffix is provided, the default comparison is equality (`EQ`).
      #
      # query - [String, Hash] The query for searching. This can be either:
      #   - A String: for full-text search.
      #   - A Hash: where each key represents a property and may have suffixes for the comparison
      #     (e.g., `{ email_contains: 'example.org', age_gt: 30 }`).
      # properties - An optional array of property names to return in the search results. [Array<String>]
      #   If not specified or empty, HubSpot will return the default set of properties.
      # page_size - The number of results to return per page (default is 10 for contacts and 100 for everything else).
      #
      # Example Usage:
      #   # Full-text search for 'example.org':
      #   contacts = Hubspot::Contact.search(query: "example.org",
      #                                      properties: ["email", "firstname", "lastname"], page_size: 50)
      #
      #   # Search for contacts whose email contains 'example.org' and are older than 30:
      #   contacts = Hubspot::Contact.search(
      #     query: { email_contains: 'example.org', age_gt: 30 },
      #     properties: ["email", "firstname", "lastname"],
      #     page_size: 50
      #   )
      #
      # Returns [PagedCollection] A paged collection of results that can be iterated over.
      def search(query:, properties: [], page_size: 100)
        search_body = {}

        # Add properties if specified
        search_body[:properties] = properties unless properties.empty?

        # Handle the query using case-when for RuboCop compliance
        case query
        when String
          search_body[:query] = query
        when Hash
          search_body[:filterGroups] = build_filter_groups(query)
        else
          raise ArgumentError, 'query must be either a string or a hash'
        end

        # Add the page size (passed as limit to the API)
        search_body[:limit] = page_size

        # Perform the search and return a PagedCollection
        PagedCollection.new(
          url: "/crm/v3/objects/#{resource_name}/search",
          params: search_body,
          resource_class: self,
          method: :post
        )
      end

      # rubocop:enable Metrics/MethodLength

      # Define the resource name based on the class
      def resource_name
        name = self.name.split('::').last.downcase
        if name.end_with?('y')
          name.gsub(/y$/, 'ies') # Company -> companies
        else
          "#{name}s" # Contact -> contacts, Deal -> deals
        end
      end

      private

      # Instantiate a single resource object from the response
      def instantiate_from_response(response)
        data = handle_response(response)
        new(data) # Passing full response data to initialize
      end

      # Convert simple filters to HubSpot's filterGroups format
      def build_filter_groups(filters)
        filter_groups = [{ filters: [] }]

        filters.each do |key, value|
          filter = extract_property_and_operator(key)
          value_key = value.is_a?(Array) ? :values : :value
          filter[value_key] = value
          filter_groups.first[:filters] << filter
        end

        filter_groups
      end

      # Extract property name and operator from the key
      def extract_property_and_operator(key)
        OPERATOR_MAP.each do |suffix, hubspot_operator|
          if key.to_s.end_with?(suffix)
            return {
              propertyName: key.to_s.sub(suffix, ''),
              operator: hubspot_operator
            }
          end
        end

        # Default to 'EQ' operator if no suffix is found
        { propertyName: key.to_s, operator: 'EQ' }
      end
    end

    # rubocop:disable Ling/MissingSuper

    # Public: Initialize a resouce
    #
    # data - [2D Hash, nested Hash] data to initialise the resourse This can be either:
    #   - A Simple 2D Hash, key value pairs of property => value (for the create option)
    #   - A structured hash consisting of { id: <hs_object_id>, properties: {}, ... }
    #     This is the same structure as per the API, and can be rebuilt if you store the id
    #     of the object against your own data
    #
    # Example:
    #   contact = Hubspot::Contact.new(firstname: 'Luke', lastname: 'Skywalker', email: 'luke@jedi.org')
    #   contact.persisted? # false
    #   contact.save # creates the record in Hubspot
    #   contact.persisted? # true
    #   puts "Contact saved with hubspot id #{contact.id}"
    #
    #   existing_contact = Hubspot::Contact.new(id: hubspot_id, properties: contact.to_hubspot_properties)
    def initialize(data = {})
      data.transform_keys!(&:to_s)
      @id = extract_id(data)
      @properties = {}
      @metadata = {}
      if @id
        initialize_from_api(data)
      else
        initialize_new_object(data)
      end
    end

    # rubocop:enable Ling/MissingSuper

    # Determine the state of the object
    #
    # Returns Boolean
    def changes?
      !@changes.empty?
    end

    # Create or Update the resource.
    # If the resource was already persisted (e.g. it was retrieved from the API)
    # it will be updated using values from @changes
    #
    # If the resource is new (no id) it will be created
    #
    # Returns Boolean
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

    # If the resource exists in Hubspot
    #
    # Returns Boolean
    def persisted?
      @id ? true : false
    end

    # Update the resource
    #
    # params - hash of properties to update in key value pairs
    #
    # Example:
    #   contact = Hubspot::Contact.find(hubspot_contact_id)
    #   contact.update(status: 'gold customer', last_contacted_at: Time.now.utc.iso8601)
    #
    # Returns Boolean
    def update(params)
      raise 'Not able to update as not persisted' unless persisted?

      params.each do |key, value|
        send("#{key}=", value) # This will trigger the @changes tracking via method_missing
      end

      save
    end

    # Archive the object in Hubspot
    #
    # Example:
    #   company = Hubspot::Company.find(hubspot_company_id)
    #   company.delete
    #
    def delete
      self.class.archive(id)
    end
    alias archive delete

    def resource_name
      self.class.resource_name
    end

    # rubocop:disable Metrics/MethodLength

    # getter: Check the properties and changes hashes to see if the method
    # being called is a key, and return the corresponding value
    # setter: If the method ends in "=" persist the value in the changes hash
    # (when it is different from the corresponding value in properties if set)
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

    # Ensure respond_to_missing? handles existing keys in the properties anc changes hashes
    def respond_to_missing?(method_name, include_private = false)
      property_name = method_name.to_s.chomp('=')
      @properties.key?(property_name) || @changes.key?(property_name) || super
    end

    private

    # Extract ID from data and convert to integer
    def extract_id(data)
      data['id'] ? data['id'].to_i : nil
    end

    # Initialize from API response, separating metadata from properties
    def initialize_from_api(data)
      @metadata = extract_metadata(data)
      properties_data = data['properties'] || {}

      properties_data.each do |key, value|
        if METADATA_FIELDS.include?(key)
          @metadata[key] = value
        else
          @properties[key] = value
        end
      end

      @changes = {}
    end

    # Initialize a new object (no API response)
    def initialize_new_object(data)
      @properties = {}
      @changes = data.transform_keys(&:to_s)
      @metadata = {}
    end

    # Extract metadata from data, excluding properties
    def extract_metadata(data)
      data.reject { |key, _| key == 'properties' }
    end

    # Create a new resource
    def create_new
      created_resource = self.class.create(@changes)
      @id = created_resource.id
      @id ? true : false
    end
  end
  # rubocop:enable Metrics/ClassLength
end
