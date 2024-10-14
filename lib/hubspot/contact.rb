# frozen_string_literal: true

module Hubspot
  class Contact < Resource
    # def required_properties
    #   %w[email firstname lastname]
    # end

    private

    def metadata_field?(key)
      METADATA_FIELDS.include?(key) || key.start_with?('hs_')
    end

    class << self
      # Finds a contact by the hubspotutk cookie
      #
      # token - the hubspot tracking token (stored from the hubspotutk cookie value)
      # properties: - Optional list of properties to return.
      #   Note: If properties are specified 2 calls to the api will be made because
      #   at this time you can only search by the token using the v1 api
      #   from which we
      #
      # Example:
      #   properties = %w[firstname lastname email last_contacted]
      #   contact = Hubspot::Contact.find_by_token(hubspotutk_cookie_value, properties)
      #
      # Returns An instance of the resource.
      def find_by_token(token, properties: [])
        all_properties = build_property_list(properties)
        query_props = all_properties.map { |prop| "property=#{prop}" }
        query_string = query_props.concat(['propertyMode=value_only']).join('&')

        # Make the original API request, manually appending the query string
        response = get("/contacts/v1/contact/utk/#{token}/profile?#{query_string}")

        # Only modify the response if it's successful (status 200 OK)
        if response.success?
          # Convert the v1 response body (parsed_response) to a v3 structure
          v3_response_hash = convert_v1_response(response.parsed_response, all_properties)

          # Modify the existing response object by updating its `parsed_response`
          response.instance_variable_set(:@parsed_response, v3_response_hash)
        end

        # Pass the (potentially modified) HTTParty response to the next step
        instantiate_from_response(response)
      end

      private

      def convert_v1_response(v1_response, property_list)
        # Extract the `vid` as `id`
        v3_response = {
          'id' => v1_response['vid']
        }

        properties = property_list.each_with_object({}) do |property, hash|
          hash[property] = v1_response.dig('properties', property, 'value')
        end

        # Build the v3 structure
        v3_response['properties'] = properties

        v3_response
      end
    end
  end
end
