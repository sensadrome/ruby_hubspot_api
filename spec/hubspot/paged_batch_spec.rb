# frozen_string_literal: true

RSpec.describe Hubspot::PagedBatch, configure_hubspot: true do
  let(:contacts_batch_read_page) { 'https://api.hubapi.com/crm/v3/objects/contacts/batch/read' }
  let(:contact_ids) { (1...15).to_a }

  let(:contacts) { Hubspot::Contact.batch_read(contact_ids) }
  context 'when hitting the rate limit' do
    before do
      # Stub the request to return a 429 rate-limit response (with immediate retry ;)
      stub_request(:post, contacts_batch_read_page)
        .to_return(status: 429, body: 'Rate limit exceeded', headers: { 'Retry-After' => '0' })

      # Redefine the MAX_RETRIES constant to 2 for this test
      stub_const('Hubspot::ApiClient::MAX_RETRIES', 2)
    end

    it 'makes the correct number of retry attempts when receiving a 429 rate limit response' do
      expect { contacts.each_page { |page| page } }.to raise_error(Hubspot::RateLimitExceededError)
      expect(WebMock).to have_requested(:post, contacts_batch_read_page).times(3)
    end
  end

  context 'when fetching all 15 contacts' do
    def new_contact(seq)
      { 'id' => seq + 1, 'properties' => { 'firstname' => "Contact #{seq + 1}" } }
    end

    before do
      stub_const('Hubspot::PagedBatch::MAX_LIMIT', 10)
      # Stub the first page of contacts (10 contacts) with a 'next' paging parameter
      stub_request(:post, contacts_batch_read_page)
        .with(body: /"id":10/)
        .to_return(
          status: 200,
          body: {
            'results' => Array.new(10) { |i| new_contact(i) }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Stub the second page of contacts (5 contacts) with no 'next' page
      stub_request(:post, contacts_batch_read_page)
        .with(body: /"id":11/)
        .to_return(
          status: 200,
          body: {
            'results' => Array.new(5) { |i| new_contact(i + 10) }
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
      expect(a_request(:post, contacts_batch_read_page)).to have_been_made.twice
    end

    it 'can be iterated over and it will fetch 2 pages' do
      # Ensure the correct number of contacts are retrieved
      contacts.each do |contact|
        expect(contact).to be_a(Hubspot::Contact)
      end

      # Verify that both page requests were made
      expect(a_request(:post, contacts_batch_read_page)).to have_been_made.twice
      expect(WebMock).to have_requested(:post, contacts_batch_read_page).with(body: Regexp.new({ id: 10 }.to_json)).once
    end
  end
end
