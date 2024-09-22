# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe 'Hubspot Errors' do
  include_examples 'hubspot configuration'

  let(:contacts_list_page) { 'https://api.hubapi.com/crm/v3/objects/contacts' }

  before do
    # Stub the request to return an unhandled error
    stub_request(:get, contacts_list_page).to_return(status: 418, body: 'I am a teapot')
  end

  context 'when the api send back an unexpected error' do
    it 'will raise a default error' do
      expect { Hubspot::Contact.list.all }.to raise_error(Hubspot::RequestError)
    end
  end
end
