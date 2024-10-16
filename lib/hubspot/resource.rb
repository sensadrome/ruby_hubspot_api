# frozen_string_literal: true

require_relative './api_client'
require_relative './paged_collection'
require_relative './paged_batch'

module Hubspot
  # rubocop:disable Metrics/ClassLength

  # HubSpot Resource Base Class
  # This class provides common functionality for interacting with
  # HubSpot API resources such as Contacts, Companies, etc
  #
  # It supports common operations like finding, creating, updating,
  # and deleting resources, as well as batch operations.
  #
  # This class is meant to be inherited by specific resources
  # like `Hubspot::Contact`.
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
      # properties - an array of property names to fetch in the result
      #
      # Example:
      #   contact = Hubspot::Contact.find(1)
      #   contact = Hubspot::Contact.find(1, properties: %w[email firstname lastname custom_field])
      #
      # Returns An instance of the resource.
      def find(id, properties: nil)
        all_properties = build_property_list(properties)
        if all_properties.is_a?(Array) && !all_properties.empty?
          params = { query: { properties: all_properties } }
        end
        response = get("#{api_root}/#{resource_name}/#{id}", params || {})
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

        all_properties = build_property_list(properties)
        params[:properties] = all_properties unless all_properties.empty?

        response = get("#{api_root}/#{resource_name}/#{value}", query: params)
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
        response = post("#{api_root}/#{resource_name}", body: { properties: params }.to_json)
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
      # Returns True if the update was successful
      def update(id, params)
        response = patch("#{api_root}/#{resource_name}/#{id}",
                         body: { properties: params }.to_json)
        handle_response(response)

        true
      end

      # Deletes a resource by ID.
      #
      # id - The ID of the resource to delete.
      #
      # Example:
      #   Hubspot::Contact.archive(1)
      #
      # Returns True if the deletion was successful
      def archive(id)
        response = delete("#{api_root}/#{resource_name}/#{id}")
        handle_response(response)

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
        all_properties = build_property_list(params[:properties])

        if all_properties.is_a?(Array) && !all_properties.empty?
          params[:properties] = all_properties.join(',')
        end

        PagedCollection.new(
          url: list_page_uri,
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
      # Returns [PagedBatch] A paged batch of resources
      def batch_read(object_ids = [], properties: [], id_property: 'id')
        params = {}
        params[:idProperty] = id_property unless id_property == 'id'
        params[:properties] = properties unless properties.blank?

        PagedBatch.new(
          url: "#{api_root}/#{resource_name}/batch/read",
          params: params.empty? ? nil : params,
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
      #   Hubspot::Contact.batch_read_all(hubspot_contact_ids)
      #
      # Returns [Hubspot::Batch] A batch of resources that can be operated on further
      def batch_read_all(object_ids = [], properties: [], id_property: 'id')
        Hubspot::Batch.read(self, object_ids, properties: properties, id_property: id_property)
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
      #   values_for_select = property.options.each_with_object({}) do |prop, hash|
      #     hash[prop['value']] = prop['label']
      #   end
      #
      # Returns [Hubspot::Property] A hubspot property
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
      # This method allows searching for resources by passing a query in the form of a string
      # (for full-text search) or a hash with special suffixes on the keys to
      # define different comparison operators.
      #
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
      # If no value is provided, or is empty the NOT_HAS_PROPERTY operator will be used
      #
      # query - [String, Hash] The query for searching. This can be either:
      #   - A String: for full-text search.
      #   - A Hash: where each key represents a property and may have suffixes for the comparison
      #     (e.g., `{ email_contains: 'example.org', age_gt: 30 }`).
      # properties - An optional array of property names to return in the search results.
      #   If not specified or empty, HubSpot will return the default set of properties.
      # page_size - The number of results to return per page
      #   (default is 10 for contacts and 100 for everything else).
      #
      # Example Usage:
      #   # Full-text search for 'example.org':
      #   props = %w[email firstname lastname]
      #   contacts = Hubspot::Contact.search(query: "example.org", properties: props, page_size: 50)
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
          url: "#{api_root}/#{resource_name}/search",
          params: search_body,
          resource_class: self,
          method: :post
        )
      end

      # rubocop:enable Metrics/MethodLength

      # The root of the api call. Mostly this will be "crm"
      # but you can override this to account for a different
      # object hierarchy

      # Define the resource name based on the class
      def resource_name
        name = self.name.split('::').last.downcase
        if name.end_with?('y')
          name.gsub(/y$/, 'ies') # Company -> companies
        else
          "#{name}s" # Contact -> contacts, Deal -> deals
        end
      end

      # List of properties that will always be retrieved
      # should be overridden in specific resource class
      def required_properties
        []
      end

      private

      def api_root
        '/crm/v3/objects'
      end

      def list_page_uri
        "#{api_root}/#{resource_name}"
      end

      # Instantiate a single resource object from the response
      def instantiate_from_response(response)
        data = handle_response(response)
        new(data) # Passing full response data to initialize
      end

      # Convert simple filters to HubSpot's filterGroups format
      def build_filter_groups(filters)
        filter_groups = [{ filters: [] }]

        filters.each do |key, value|
          filter = extract_property_and_operator(key, value)
          value_key = value.is_a?(Array) ? :values : :value
          filter[value_key] = value unless value.blank?
          filter_groups.first[:filters] << filter
        end

        filter_groups
      end

      # Extract property name and operator from the key
      def extract_property_and_operator(key, value)
        return { propertyName: key.to_s, operator: 'NOT_HAS_PROPERTY' } if value.blank?

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

      # Internal make a list of properties to request from the API
      # will be merged with any required_properties defined on the class
      def build_property_list(properties)
        properties = [] unless properties.is_a?(Array)
        raise 'Must be an array' unless required_properties.is_a?(Array)

        properties.concat(required_properties).uniq
      end
    end

    # rubocop:disable Lint/MissingSuper

    # Public: Initialize a resouce
    #
    # data - [2D Hash, nested Hash] data to initialise:
    #   - The response from the api will be of the form:
    #       { id: <hs_object_id>, properties: { "email": "john@example.org" ... }, ... }
    #
    #   - A Simple 2D Hash, key value pairs in the form:
    #       { email: 'john@example.org', firstname: 'John', lastname: 'Smith' }
    #
    #   - A structured hash consisting of { id: <hs_object_id>, properties: {}, ... }
    #     This is the same structure as per the API, and can be rebuilt if you store the id
    #     of the object against your own data
    #
    # Example:
    #   attrs = { firstname: 'Luke', lastname: 'Skywalker', email: 'luke@jedi.org' }
    #   contact = Hubspot::Contact.new(attrs)
    #   contact.persisted? # false
    #   contact.save # creates the record in Hubspot
    #   contact.persisted? # true
    #   puts "Contact saved with hubspot id #{contact.id}"
    #
    #   existing_contact = Hubspot::Contact.new(id: hubspot_id, properties: contact.to_hubspot)
    def initialize(data = {})
      data.transform_keys!(&:to_s)
      @id = extract_id(data.delete('id'))
      @properties = {}
      @metadata = {}
      if @id
        initialize_from_api(data)
      else
        initialize_new_object(data)
      end
    end
    # rubocop:enable Lint/MissingSuper

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

    def save!
      raise NothingToDoError, 'Nothing to save' unless changes?

      save
    end

    # If the resource exists in Hubspot
    #
    # Returns Boolean
    def persisted?
      @id ? true : false
    end

    # Public - Update the resource and persist to the api
    #
    # attributes - hash of properties to update in key value pairs
    #
    # Example:
    #   contact = Hubspot::Contact.find(hubspot_contact_id)
    #   contact.update(status: 'gold customer', last_contacted_at: Time.now.utc.iso8601)
    #
    # Returns Boolean
    def update(attributes)
      raise 'Not able to update as not persisted' unless persisted?

      update_attributes(attributes)

      save
    end

    # Public - Update resource attributes
    #
    # Does not persist to the api but processes each attribute correctly
    #
    # Example:
    #   contact = Hubspot::Contact.find(hubspot_contact_id)
    #   contact.changes? # false
    #   contact.update_attributes(education: 'Graduate', university: 'Life')
    #   contact.education # Graduate
    #   contact.changes? # true
    #   contact.changes # { "education" => "Graduate", "university" => "Life" }
    #
    # Returns Hash of changes
    def update_attributes(attributes)
      raise ArgumentError, 'must be a hash' unless attributes.is_a?(Hash)

      attributes.each do |key, value|
        send("#{key}=", value) # This will trigger the @changes tracking via method_missing
      end
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
        add_accessors attribute
        return send("#{attribute}=", new_value)
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

    # Initialize from API response, separating metadata from properties
    def initialize_from_api(data)
      @changes = data.delete('changes')&.transform_keys!(&:to_s) || {}

      if data['properties']
        @metadata = data.reject { |key, _v| key == 'properties' }
        handle_properties(data['properties'])
      else
        handle_properties(data)
      end
    end

    private

    # Extract ID from data and convert to integer
    def extract_id(id)
      id&.to_i
    end

    def handle_properties(properties_data)
      properties_data.each do |attribute, value|
        if metadata_field?(attribute)
          @metadata[attribute.to_s] = value
        else
          add_accessors attribute.to_s
          @properties[attribute.to_s] = value
        end
      end
    end

    def add_accessors(attribute)
      add_accessors_setter(attribute)
      add_accessors_getter(attribute)
    end

    def add_accessors_setter(attribute)
      # Define the setter method
      define_singleton_method("#{attribute}=") do |new_value|
        # Track changes only if the value has actually changed
        if @properties[attribute] != new_value
          @changes[attribute] = new_value
        else
          @changes.delete(attribute) # Remove from changes if it reverts to the original value
        end

        new_value
      end
    end

    def add_accessors_getter(attribute)
      # Define the getter method
      define_singleton_method(attribute) do
        # Return from changes if available, else return from properties
        return @changes[attribute] if @changes.key?(attribute)

        @properties[attribute] if @properties.key?(attribute)
      end
    end

    # allows overwriting in other resource classes
    def metadata_field?(key)
      METADATA_FIELDS.include?(key)
    end

    # Initialize a new object (no API response)
    def initialize_new_object(data)
      @properties = {}
      @changes = data.transform_keys(&:to_s)
      @metadata = {}
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
