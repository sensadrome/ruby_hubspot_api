# frozen_string_literal: true

module Hubspot
  class Form < Resource
    # :nocov:
    def inspect
      "#<#{self.class.name} " \
      "@name=#{name}, " \
      "@fieldGroups=#{respond_to?('fieldGroups') ? fieldGroups.size : '-'}>"
    end
    # :nocov:

    class << self
      private

      def api_root
        '/marketing/v3'
      end
    end

    private

    # dont convert (from string)
    def extract_id(id)
      id
    end

    def metadata_fields
      %w[createdAt updatedAt archived].freeze
    end
  end
end
