# frozen_string_literal: true

module Hubspot
  # Properties from the object schema
  class Property < OpenStruct
    # :nocov:
    def inspect
      included_keys = %i[name type fieldType hubspotDefined]
      filtered_hash = to_h.slice(*included_keys)
      formatted_attrs = filtered_hash.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')
      "#<#{self.class} #{formatted_attrs}>"
    end
    # :nocov:
  end
end
