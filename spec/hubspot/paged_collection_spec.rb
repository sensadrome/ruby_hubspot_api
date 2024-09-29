# frozen_string_literal: true

RSpec.describe Hubspot::PagedCollection do
  include_examples 'hubspot configuration'

  let(:contacts_list_page) { 'https://api.hubapi.com/crm/v3/objects/contacts' }
  let(:contacts) { Hubspot::Contact.list }

  context 'when hitting the rate limit' do
    before do
      # Stub the request to return a 429 rate-limit response (with immediate retry ;)
      stub_request(:get, contacts_list_page)
        .to_return(status: 429, body: 'Rate limit exceeded', headers: { 'Retry-After' => '0' })

      # Redefine the MAX_RETRIES constant to 2 for this test
      stub_const('Hubspot::ApiClient::MAX_RETRIES', 2)
    end

    it 'makes the correct number of retry attempts when receiving a 429 rate limit response' do
      expect { contacts.each_page { |page| page } }.to raise_error(Hubspot::RateLimitExceededError)
      expect(WebMock).to have_requested(:get, contacts_list_page).times(3)
    end
  end

  context 'when fetching all 15 contacts' do
    def new_contact(seq)
      { 'id' => "contact_#{seq + 1}", 'properties' => { 'firstname' => "Contact #{seq + 1}" } }
    end

    before do
      # Stub the first page of contacts (10 contacts) with a 'next' paging parameter
      stub_request(:get, contacts_list_page)
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: {
            'results' => Array.new(10) { |i| new_contact(i) },
            'paging' => { 'next' => { 'after' => '10' } }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Stub the second page of contacts (5 contacts) with no 'next' page
      stub_request(:get, contacts_list_page)
        .with(query: hash_including({ 'after' => '10' }))
        .to_return(
          status: 200,
          body: {
            'results' => Array.new(5) { |i| new_contact(i + 10) },
            'paging' => {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    let(:all_contacts) { contacts.all }

    it 'fetches all contacts in two pages and makes two requests' do
      # Ensure the correct number of contacts are retrieved
      expect(all_contacts.size).to eq(15)

      # Check the contacts for correctness
      expect(all_contacts.map { |contact| contact.properties['firstname'] }).to include('Contact 1', 'Contact 15')

      # Verify that both page requests were made
      expect(a_request(:get, contacts_list_page)).to have_been_made.once
      expect(WebMock).to have_requested(:get, contacts_list_page).with(query: { 'after' => '10' }).once
    end

    it 'can be iterated over and it will fetch 2 pages' do
      # Ensure the correct number of contacts are retrieved
      contacts.each do |contact|
        expect(contact).to be_a(Hubspot::Contact)
      end

      # Verify that both page requests were made
      expect(a_request(:get, contacts_list_page)).to have_been_made.once
      expect(WebMock).to have_requested(:get, contacts_list_page).with(query: { 'after' => '10' }).once
    end
  end
end
