# frozen_string_literal: true

def vcr_record_mode
  ENV.fetch('VCR_RECORD_MODE', 'none').to_sym
end

# spec/spec_helper.rb
VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

  # Disallow HTTP requests when no cassette is used
  c.allow_http_connections_when_no_cassette = false

  # set the record mode
  c.default_cassette_options = { record: vcr_record_mode }

  # Allow real requests only if the environment variable is set
  if ENV['VCR_ALLOW_REQUESTS'] == 'true'
    WebMock.allow_net_connect!
  else
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  %w[HUBSPOT_ACCESS_TOKEN HUBSPOT_CLIENT_SECRET HUBSPOT_PORTAL_ID].each do |secret|
    c.filter_sensitive_data("<#{secret}>") { ENV[secret] }
  end
end

# if we are just going to specify the cassette, allow shorthand...
# describe 'a test that makes http requests', cassette: 'path/to/cassette'
RSpec.configure do |config|
  config.around(:each) do |example|
    if example.metadata[:cassette]
      cassette_name = example.metadata[:cassette]
      VCR.use_cassette(cassette_name) { example.run }
    else
      example.run
    end
  end
end
