# frozen_string_literal: true

RSpec.describe Hubspot::PagedCollection, configure_hubspot: true do
  let(:contacts_list_page) { 'https://api.hubapi.com/crm/v3/objects/contacts' }
  let(:contacts_collection) { Hubspot::Contact.list }

  describe 'filtering' do
    let(:collection_params) { collection_to_check.instance_variable_get('@params') }

    let(:filter_groups) do
      return unless collection_params.is_a?(Hash)

      collection_params[:filterGroups]
    end

    let(:filters) do
      return unless filter_groups.is_a?(Array)
      return unless filter_groups.first.is_a?(Hash)

      filter_groups.first[:filters]
    end
    let(:search_collection) { Hubspot::Contact.all }

    context 'using an empty search collection from a resource set' do
      let(:collection_to_check) { search_collection }

      it 'should have empty filters' do
        expect(filter_groups).to be(nil)
      end

      describe '#where' do
        let(:filtered_collection) { search_collection.where(email_contains: 'example.org') }
        let(:collection_to_check) { filtered_collection }

        it 'returns a PagedCollection' do
          expect(filtered_collection).to be_a(Hubspot::PagedCollection)
        end

        it 'updates the filters' do
          expect(filter_groups).not_to be_empty
        end
      end

      describe '#where!' do
        let(:filtered_collection) { search_collection.where(email_contains: 'example.org') }

        it 'returns a PagedCollection' do
          expect(filtered_collection).to be_a(Hubspot::PagedCollection)
        end

        it 'updates the filters in the original collection' do
          _ignore = filtered_collection
          expect(filter_groups).not_to be_empty
        end
      end
    end

    describe 'when called in a chain' do
      let(:collection_to_check) { filtered_collection }
      let(:filtered_collection) do
        search_collection.where(email_contains: 'example.org').where(enquiry_status: 'new')
      end

      it 'will add to the filters within the filter groups' do
        expect(filters.length).to eq(2)
      end
    end
  end

  context 'when hitting the rate limit' do
    before do
      # Stub the request to return a 429 rate-limit response (with immediate retry ;)
      stub_request(:get, contacts_list_page)
        .to_return(status: 429, body: 'Rate limit exceeded', headers: { 'Retry-After' => '0' })

      # Redefine the MAX_RETRIES constant to 2 for this test
      stub_const('Hubspot::ApiClient::MAX_RETRIES', 2)
    end

    it 'makes the correct number of retry attempts when receiving a 429 rate limit response' do
      expect { contacts_collection.each_page { |page| page } }.to raise_error(Hubspot::RateLimitExceededError)
      expect(WebMock).to have_requested(:get, contacts_list_page).times(3)
    end
  end

  context 'within the rate limit' do
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

      let(:all_contacts) { contacts_collection.all }

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
        contacts_collection.each do |contact|
          expect(contact).to be_a(Hubspot::Contact)
        end

        # Verify that both page requests were made
        expect(a_request(:get, contacts_list_page)).to have_been_made.once
        expect(WebMock).to have_requested(:get, contacts_list_page).with(query: { 'after' => '10' }).once
      end
    end

    describe '.total' do
      def new_contact(seq)
        id = seq + 1
        {
          id: id,
          properties: {
            firstname: "Contact #{id}",
            email: "contact#{id}.test@example.org"
          }
        }
      end

      before do
        # Stub the first page of contacts (10 contacts) with a 'next' paging parameter
        stub_request(:post, contacts_search_page)
          .with(query: hash_including({}))
          .to_return(
            status: 200,
            body: {
              'results' => Array.new(5) { |i| new_contact(i) },
              'total' => 5
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      let(:search_domain) { ENV.fetch('HUBSPOT_SEARCH_TEST_DOMAIN', 'example.org') }
      let(:contacts_search_collection) { Hubspot::Contact.search(query: search_params) }
      let(:contacts_search_page) { 'https://api.hubapi.com/crm/v3/objects/contacts/search' }

      context 'when using a collection based on search' do
        let(:search_params) { { 'email_contains' => search_domain } }

        it 'will return the total by making a single request' do
          # Expect the result not to be empty
          expect(contacts_search_collection.total).to be_a(Integer)
          expect(WebMock).to have_requested(:post, contacts_search_page).with(body: a_string_including('"limit":1')).once
        end
      end

      context 'when using a collection based on list' do
        it 'will raise an error' do
          # Expect the result not to be empty
          expect { contacts_collection.total }.to raise_error(Hubspot::NotImplementedError)
        end
      end
    end
  end
end
