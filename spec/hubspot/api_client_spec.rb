# frozen_string_literal: true

RSpec.describe Hubspot::ApiClient do
  include_examples 'hubspot configuration'
  let(:logger) { instance_double(Logger) }

  before do
    # Mock the logger to capture the output
    allow(Hubspot).to receive(:logger).and_return(logger)

    # Mock the logger methods to allow checking log messages
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)

    # Stub the actual HTTP POST request using WebMock's `stub_request`
    stub_request(:post, %r{/crm/v3/objects/contacts})
      .to_return(status: 200, body: '{"success":true}', headers: { 'Content-Type' => 'application/json' })
  end

  context 'when the log level is set to debug' do
    before do
      # Ensure that logger.debug? returns true
      allow(logger).to receive(:debug?).and_return(true)
    end

    it 'logs request and response body during a contact POST request' do
      # Make a POST request using the Contact class
      Hubspot::Contact.create(name: 'John Doe')

      # Check that logger.info was called
      expect(logger).to have_received(:info).with(/POST .* took \d+\.\d+s with status 200/)

      # Check that logger.debug was called for both request and response bodies
      expect(logger).to have_received(:debug).with(/Request body:/)
      expect(logger).to have_received(:debug).with(/Response body:/)
    end
  end

  context 'when the log level is not set to debug' do
    before do
      # Ensure that logger.debug? returns false
      allow(logger).to receive(:debug?).and_return(false)
    end

    it 'does not log request and response body during a contact POST request' do
      # Make a POST request using the Contact class
      Hubspot::Contact.create(name: 'John Doe')

      # Check that logger.info was called
      expect(logger).to have_received(:info).with(/POST .* took \d+\.\d+s with status 200/)

      # Ensure that logger.debug was NOT called
      expect(logger).not_to have_received(:debug)
    end
  end
end
