# frozen_string_literal: true

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

    it 'sets and retrieves the client_secret via the Hubspot module' do
      Hubspot.configure do |config|
        config.client_secret = 'test_client_secret'
      end

      expect(Hubspot.config.client_secret).to eq('test_client_secret')
    end

    it 'sets and retrieves the default request timeout via the Hubspot module' do
      Hubspot.configure do |config|
        config.timeout = 10
      end

      expect(Hubspot.config.timeout).to eq(10)
      expect(Hubspot::ApiClient.default_options[:timeout]).to eq(10)
    end

    it 'sets and retrieves the open_timeout via the Hubspot module' do
      Hubspot.configure do |config|
        config.open_timeout = 10
      end

      expect(Hubspot.config.open_timeout).to eq(10)
      expect(Hubspot::ApiClient.default_options[:open_timeout]).to eq(10)
    end

    it 'sets and retrieves the read_timeout via the Hubspot module' do
      Hubspot.configure do |config|
        config.read_timeout = 10
      end

      expect(Hubspot.config.read_timeout).to eq(10)
      expect(Hubspot::ApiClient.default_options[:read_timeout]).to eq(10)
    end

    context 'when RUBY_VERSION >= 2.6' do
      it 'sets and retrieves the write_timeout via the Hubspot module', if: RUBY_VERSION >= '2.6' do
        Hubspot.configure do |config|
          config.write_timeout = 10
        end

        expect(Hubspot.config.write_timeout).to eq(10)
        expect(Hubspot::ApiClient.default_options[:write_timeout]).to eq(10)
      end
    end

    context 'when RUBY_VERSION < 2.6' do
      it 'will not write_timeout via the Hubspot module when provided', if: RUBY_VERSION < '2.6' do
        Hubspot.configure do |config|
          config.write_timeout = 10
        end

        expect(Hubspot.config.write_timeout).to eq(10)
        expect(Hubspot::ApiClient.default_options[:write_timeout]).to be_nil
      end
    end

    describe 'with the HUBSPOT_LOG_LEVEL env var' do
      before(:each) { @original_level = ENV['HUBSPOT_LOG_LEVEL'] }
      after(:each) { ENV['HUBSPOT_LOG_LEVEL'] = @original_level }

      context 'is set' do
        it 'will set the appropriate log level' do
          %w[debug info warn error fatal].each do |level|
            ENV['HUBSPOT_LOG_LEVEL'] = level
            Hubspot.configure { |config| }
            expect(Hubspot.config.log_level).to eq(Logger.const_get(level.upcase))
            Hubspot.config = nil
          end
        end

        it 'will default to INFO if an incorrect level name is provided' do
          ENV['HUBSPOT_LOG_LEVEL'] = 'non-existent-level'
          Hubspot.configure { |config| }
          expect(Hubspot.config.log_level).to eq(Logger::INFO)
          Hubspot.config = nil
        end
      end

      context 'is not set' do
        context 'in a Rails test environment' do
          before do
            stub_const('Rails', Class.new) unless defined?(Rails)
            allow(Rails).to receive_message_chain(:env, :test?).and_return(true)
          end

          it 'will default to FATAL' do
            ENV['HUBSPOT_LOG_LEVEL'] = nil
            Hubspot.configure { |config| }
            expect(Hubspot.config.log_level).to eq(Logger::FATAL)
          end
        end

        context 'in a non Rails environment' do
          it 'will default to INFO' do
            ENV['HUBSPOT_LOG_LEVEL'] = nil
            Hubspot.configure { |config| }
            expect(Hubspot.config.log_level).to eq(Logger::INFO)
          end
        end
      end
    end

    context 'when no configuration is set' do
      describe 'when accessing the config' do
        it 'returns nil for access_token, portal_id, client_id, and client_secret' do
          expect(Hubspot.config.access_token).to be_nil
          expect(Hubspot.config.portal_id).to be_nil
          expect(Hubspot.config.client_secret).to be_nil
        end
      end

      describe 'when trying to access the API' do
        it 'raises an error' do
          expect { Hubspot::Contact.list.first }.to raise_error(Hubspot::NotConfiguredError)
        end
      end
    end
  end
end
