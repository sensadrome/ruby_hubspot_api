# frozen_string_literal: true

RSpec.describe Hubspot::Batch do
  include_examples 'hubspot configuration'
  let(:company) do
    instance_double('Company', changes: { name: 'Acme Corp' }, resource_name: 'companies', internal_id: 123)
  end

  describe 'validity' do
    let(:resource1) { instance_double('Resource', changes: { name: 'John' }, resource_name: 'contacts') }
    let(:resource2) { instance_double('Resource', changes: { name: 'Jane' }, resource_name: 'contacts') }
    let(:invalid_resource) { instance_double('InvalidResource', resource_name: 'invalid_resource') }
    context 'with valid resources' do
      let(:batch) { Hubspot::Batch.new([resource1, resource2]) }

      it 'initializes successfully' do
        expect(batch).to be_a(Hubspot::Batch)
      end
    end

    context 'with mixed resource types' do
      it 'raises a Hubspot::ArgumentError' do
        expect { Hubspot::Batch.new([resource1, invalid_resource]) }.to raise_error(Hubspot::ArgumentError, /same type/)
      end
    end
  end

  describe '#create' do
    let(:contact1) { Hubspot::Contact.new(email: 'john@example.com', firstname: 'John', lastname: 'Doe') }
    let(:contact2) { Hubspot::Contact.new(email: 'jane@example.com', firstname: 'Jane', lastname: 'Doe') }
    let(:batch) { described_class.new([contact1, contact2], id_property: 'email') }

    let(:response_data) do
      {
        'results' => [
          { 'id' => '1', 'properties' => { 'email' => 'john@example.com', 'firstname' => 'John', 'lastname' => 'Doe' },
            'updatedAt' => Time.now.utc.iso8601(3) },
          { 'id' => '2', 'properties' => { 'email' => 'jane@example.com', 'firstname' => 'Jane', 'lastname' => 'Doe' },
            'updatedAt' => Time.now.utc.iso8601(3) }
        ]
      }
    end

    before do
      # Mock the API response to return newly created contact IDs and updated properties
      response = instance_double(HTTParty::Response, code: 200, parsed_response: response_data, success?: true)
      allow(Hubspot::Batch).to receive(:post).and_return(response)
    end

    it 'creates new contacts and updates their ids and properties' do
      batch.create

      # Expect the post method to have been called with the correct create URL
      expect(batch.class).to have_received(:post).with('/crm/v3/objects/contacts/batch/create', any_args)

      # Check that the IDs are updated
      expect(contact1.id).to eq 1
      expect(contact2.id).to eq 2

      # Ensure changes are cleared after creation
      expect(contact1.changes?).to be false
      expect(contact2.changes?).to be false

      # Ensure properties are updated, including email
      expect(contact1.properties['email']).to eq 'john@example.com'
      expect(contact1.properties['firstname']).to eq 'John'
      expect(contact1.properties['lastname']).to eq 'Doe'

      expect(contact2.properties['email']).to eq 'jane@example.com'
      expect(contact2.properties['firstname']).to eq 'Jane'
      expect(contact2.properties['lastname']).to eq 'Doe'
    end
  end

  describe '#update' do
    let(:contact) do
      instance_double('Contact', changes: { name: 'John' }, resource_name: 'contacts', email: 'john@example.com')
    end

    let(:response_data) { {} }

    before do
      # Mock HTTParty::Response to behave like a real response object
      response = instance_double(HTTParty::Response, code: 200, parsed_response: response_data, success?: true)

      # Mock the post method in ApiClient to return the HTTParty::Response object
      allow(Hubspot::Batch).to receive(:post).and_return(response)
    end

    describe 'when updating contacts' do
      let(:contact1) { Hubspot::Contact.new(id: 1, properties: { 'name' => 'John' }) }
      let(:contact2) { Hubspot::Contact.new(id: 2, properties: { 'name' => 'Jane' }) }
      let(:batch) { described_class.new([contact1, contact2], id_property: 'id') }

      let(:updated_at) { Time.now.utc.iso8601(3) }
      let(:response_data) do
        {
          'results' => [
            { 'id' => '1', 'properties' => { 'name' => 'John Updated' }, 'updatedAt' => updated_at },
            { 'id' => '2', 'properties' => { 'name' => 'Jane Updated' }, 'updatedAt' => updated_at }
          ]
        }
      end
      before do
        # Explicitly set the changes on the contacts...
        contact1.changes = { 'name' => 'John Updated' }
        contact2.changes = { 'name' => 'Jane Updated' }
      end

      it 'clears changes for all contacts after update' do
        batch.update

        expect(contact1.changes?).to be false
        expect(contact2.changes?).to be false
        expect(contact1.properties['name']).to eq 'John Updated'
        expect(contact2.properties['name']).to eq 'Jane Updated'
      end
    end

    context 'when resources are empty' do
      let(:batch) { Hubspot::Batch.new([]) }

      it 'raises an error' do
        expect { batch.update }.to raise_error(RuntimeError, 'Batch is empty')
      end
    end

    it 'makes a call to the correct update URL' do
      contacts = Array.new(5) { contact } # 5 contacts
      batch = Hubspot::Batch.new(contacts, id_property: 'email')

      batch.update # This should trigger the update endpoint

      # Expect the post method to have been called with the correct update URL
      expect(batch.class).to have_received(:post).with('/crm/v3/objects/contacts/batch/update', any_args)
    end

    context 'when batch size exceeds contact limit (10)' do
      it 'honours the batch limits and makes multiple calls' do
        contacts = Array.new(15) { contact } # 15 contacts
        batch = Hubspot::Batch.new(contacts, id_property: 'email')

        # Call update and expect post to be called twice (15 / 10 = 2 API calls)
        batch.update
        expect(batch.responses.size).to eq(2)
      end
    end

    context 'when batch size exceeds default limit (100)' do
      it 'makes more than one API call for other objects' do
        companies = Array.new(150) { company } # 150 companies

        batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

        # Call update and expect post to be called twice (150 / 100 = 2 API calls)
        batch.update
        expect(batch.responses.size).to eq(2)
      end
    end

    context 'when some resources fail' do
      before do
        partial_success_response = instance_double(HTTParty::Response, code: 207, parsed_response: {}, success?: true)
        allow(Hubspot::Batch).to receive(:post).and_return(partial_success_response)
      end

      it 'returns a partial success' do
        companies = Array.new(5) { company }
        batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

        expect(batch.update).to be true
        expect(batch.partial_success?).to be true
        expect(batch.all_successful?).to be false
      end
    end
  end

  describe '#upsert' do
    let(:companies) { Array.new(5) { company } } # 5 companies

    before do
      # Mock HTTParty::Response to behave like a response object
      response = instance_double(HTTParty::Response, code: 200, parsed_response: {}, success?: true)

      # Mock the post method in ApiClient to return the HTTParty::Response object
      allow(Hubspot::Batch).to receive(:post).and_return(response)
    end

    it 'makes a call to the correct upsert URL' do
      batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

      batch.upsert # This should trigger the upsert endpoint

      # Expect the post method to have been called with the correct upsert URL
      expect(batch.class).to have_received(:post).with('/crm/v3/objects/companies/batch/upsert', any_args)
    end

    context "when some resources don't have a value for the id property" do
      let(:incomplete_company) do
        instance_double('Company', changes: { name: 'Acme Corp' }, resource_name: 'companies', internal_id: nil)
      end
      let(:companies_including_incomplete) { (companies << incomplete_company) }

      it 'will raise an error' do
        batch = Hubspot::Batch.new(companies_including_incomplete, id_property: 'internal_id')
        expect { batch.upsert }.to raise_error(Hubspot::ArgumentError)
      end
    end
  end
  
  describe '#archive' do
    let(:contact1) { Hubspot::Contact.new(id: 1, properties: { 'email' => 'john@example.com', 'firstname' => 'John' }) }
    let(:contact2) { Hubspot::Contact.new(id: 2, properties: { 'email' => 'jane@example.com', 'firstname' => 'Jane' }) }
    let(:batch) { described_class.new([contact1, contact2], id_property: 'id') }

    before do
      # Mock the API response for archive
      response = instance_double(HTTParty::Response, code: 200, parsed_response: {}, success?: true)
      allow(Hubspot::Batch).to receive(:post).and_return(response)
    end

    it 'makes a call to the correct archive URL' do
      batch.archive

      # Ensure the post method was called with the correct URL
      expect(batch.class).to have_received(:post).with('/crm/v3/objects/contacts/batch/archive', any_args)
    end

    it 'does not call process_results after archiving' do
      # Stub process_results to track if it was called
      allow(batch).to receive(:process_results)

      batch.archive

      # Ensure that process_results was not called
      expect(batch).not_to have_received(:process_results)
    end

    context 'when some resources fail to archive' do
      before do
        # Simulate a partial success response
        partial_success_response = instance_double(HTTParty::Response, code: 207, parsed_response: {}, success?: true)
        allow(Hubspot::Batch).to receive(:post).and_return(partial_success_response)
      end

      it 'returns partial success' do
        batch.archive
        expect(batch.partial_success?).to be true
        expect(batch.all_successful?).to be false
      end
    end
  end
end
