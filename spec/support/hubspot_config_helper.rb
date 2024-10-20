# frozen_string_literal: true

module HubspotConfigHelper
  def configure_hubspot_no_auth!
    Hubspot.logger.info 'Configuring Hubspot with no-scope access_token'
    access_token = ENV['HUBSPOT_NO_AUTH_ACCESS_TOKEN'] || 'HUBSPOT_NO_AUTH_ACCESS_TOKEN'
    Hubspot.configure { |config| config.access_token = access_token }
  end

  def configure_hubspot!
    Hubspot.logger.info 'Configuring Hubspot with access_token'
    Hubspot.configure do |config|
      config.access_token  = ENV['HUBSPOT_ACCESS_TOKEN'] || 'HUBSPOT_ACCESS_TOKEN'
      config.portal_id     = ENV['HUBSPOT_PORTAL_ID'] || 'HUBSPOT_PORTAL_ID'
      config.client_secret = ENV['HUBSPOT_CLIENT_SECRET'] || 'HUBSPOT_CLIENT_SECRET'
    end
  end
end

RSpec.configure do |config|
  # Include the HubspotConfigHelper module so that its methods are available in tests
  config.include HubspotConfigHelper

  # Define a before hook that checks for :configure_hubspot metadata
  config.before(:each) do |example|
    if example.metadata[:configure_hubspot]
      case example.metadata[:configure_hubspot]
      when :no_auth
        configure_hubspot_no_auth!
      else
        configure_hubspot!
      end
    end
  end

  config.before(:all) do
    metadata = self.class.metadata
    if metadata[:configure_hubspot]
      case metadata[:configure_hubspot]
      when :no_auth
        configure_hubspot_no_auth!
      else
        configure_hubspot!
      end
    end
  end
end
