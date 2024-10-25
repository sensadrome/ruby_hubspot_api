# frozen_string_literal: true

module Hubspot
  module ResourceFilter
    module FilterGroupMethods
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
    end
  end
end
