# frozen_string_literal: true

# spec/support/shared_examples/hubspot_config.rb
RSpec.shared_examples 'hubspot configuration' do
  before do
    # Configure HubSpot using environment variables or hardcoded values
    Hubspot.configure do |config|
      config.access_token = ENV['HUBSPOT_ACCESS_TOKEN'] || 'HUBSPOT_ACCESS_TOKEN'
      config.portal_id = ENV['HUBSPOT_PORTAL_ID'] || 'HUBSPOT_PORTAL_ID'
      config.client_secret = ENV['HUBSPOT_CLIENT_SECRET'] || 'HUBSPOT_CLIENT_SECRET'
    end
  end
end
