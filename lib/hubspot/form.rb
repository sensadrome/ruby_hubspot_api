# frozen_string_literal: true

module Hubspot
  class Form < Resource
    METADATA_FIELDS = %w[createdAt updatedAt archived].freeze

    def inspect
      "#<#{self.class.name} " \
      "@name=#{name}, " \
      "@fieldGroups=#{respond_to?('fieldGroups') ? fieldGroups.size : '-'}>"
    end

    class << self
      def api_root
        '/marketing/v3'
      end
    end

    private

    # Extract ID from data and leave as a string
    def extract_id(data)
      data.delete('id')
    end
  end
end
