# spec/hubspot/config_spec.rb

require 'spec_helper'
require 'hubspot'

RSpec.describe Hubspot do
  after(:each) do
    # Reset configuration after each test
    Hubspot.config = nil
  end

  context 'when configuring the gem' do
    it 'sets and retrieves the access_token via the Hubspot module' do
      Hubspot.configure do |config|
        config.access_token = 'test_access_token'
      end

      expect(Hubspot.config.access_token).to eq('test_access_token')
    end

    it 'sets and retrieves the portal_id via the Hubspot module' do
      Hubspot.configure do |config|
        config.portal_id = 'test_portal_id'
      end

      expect(Hubspot.config.portal_id).to eq('test_portal_id')
    end

    it 'sets and retrieves the client_id via the Hubspot module' do
      Hubspot.configure do |config|
        config.client_id = 'test_client_id'
      end

      expect(Hubspot.config.client_id).to eq('test_client_id')
    end

    it 'sets and retrieves the client_secret via the Hubspot module' do
      Hubspot.configure do |config|
        config.client_secret = 'test_client_secret'
      end

      expect(Hubspot.config.client_secret).to eq('test_client_secret')
    end
  end

  context 'when no configuration is set' do
    it 'returns nil for access_token, portal_id, client_id, and client_secret' do
      expect(Hubspot.config.access_token).to be_nil
      expect(Hubspot.config.portal_id).to be_nil
      expect(Hubspot.config.client_id).to be_nil
      expect(Hubspot.config.client_secret).to be_nil
    end
  end
end
