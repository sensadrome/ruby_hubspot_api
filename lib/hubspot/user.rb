# frozen_string_literal: true

module Hubspot
  # ORM for hubspot users
  #
  # Hubspot users consist mostly of read_only attributes (you can add custom properties).
  # As such we extend this class to ensure that we retrieve useful data back from the API
  # and provide helper methods to resolve hubspot fields e.g. user.email calls user.hs_email etc
  class User < Resource
    class << self
      def required_properties
        %w[hs_email hs_given_name hs_family_name]
      end
    end

    def first_name
      hs_given_name
    end
    alias firstname first_name

    def last_name
      hs_family_name
    end
    alias lastname last_name

    def email
      hs_email
    end
  end

  Owner = User
end
