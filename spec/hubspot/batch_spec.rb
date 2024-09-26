# frozen_string_literal: true

RSpec.describe Hubspot::Batch do
  let(:resource1) { instance_double('Resource', changes: { name: 'John' }, resource_name: 'contacts') }
  let(:resource2) { instance_double('Resource', changes: { name: 'Jane' }, resource_name: 'contacts') }
  let(:invalid_resource) { instance_double('InvalidResource', resource_name: 'invalid_resource') }
  let(:contact) do
    instance_double('Contact', changes: { name: 'John' }, resource_name: 'contacts', email: 'john@example.com')
  end

  let(:company) do
    instance_double('Company', changes: { name: 'Acme Corp' }, resource_name: 'companies', internal_id: 123)
  end

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

  describe '#save' do
    before do
      # Mock HTTParty::Response to behave like a real response object
      response = instance_double(HTTParty::Response, code: 200, parsed_response: {}, success?: true)

      # Mock the post method in ApiClient to return the HTTParty::Response object
      allow_any_instance_of(Hubspot::ApiClient).to receive(:post).and_return(response)
    end

    context 'when resources are empty' do
      let(:batch) { Hubspot::Batch.new([]) }

      it 'raises an error' do
        expect { batch.save }.to raise_error(RuntimeError, 'Batch is empty')
      end
    end

    it 'makes a call to the correct update URL' do
      contacts = Array.new(5) { contact } # 5 contacts
      batch = Hubspot::Batch.new(contacts, id_property: 'email')

      batch.save # This should trigger the update endpoint

      # Expect the post method to have been called with the correct update URL
      expect(batch).to have_received(:post).with('/crm/v3/objects/contacts/batch/update', any_args)
    end

    context 'when batch size exceeds contact limit (10)' do
      it 'honours the batch limits and makes multiple calls' do
        contacts = Array.new(15) { contact } # 15 contacts
        batch = Hubspot::Batch.new(contacts, id_property: 'email')

        # Call save and expect post to be called twice (15 / 10 = 2 API calls)
        batch.save
        expect(batch.responses.size).to eq(2)
      end
    end

    context 'when batch size exceeds default limit (100)' do
      it 'makes more than one API call for other objects' do
        companies = Array.new(150) { company } # 150 companies

        batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

        # Call save and expect post to be called twice (150 / 100 = 2 API calls)
        batch.save
        expect(batch.responses.size).to eq(2)
      end
    end

    context 'when some resources fail' do
      before do
        partial_success_response = instance_double(HTTParty::Response, code: 207, parsed_response: {}, success?: true)
        allow_any_instance_of(Hubspot::ApiClient).to receive(:post).and_return(partial_success_response)
      end

      it 'returns a partial success' do
        companies = Array.new(5) { company }
        batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

        expect(batch.save).to be true
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
      allow_any_instance_of(Hubspot::ApiClient).to receive(:post).and_return(response)
    end

    it 'makes a call to the correct upsert URL' do
      batch = Hubspot::Batch.new(companies, id_property: 'internal_id')

      batch.upsert # This should trigger the upsert endpoint

      # Expect the post method to have been called with the correct upsert URL
      expect(batch).to have_received(:post).with('/crm/v3/objects/companies/batch/upsert', any_args)
    end

    context "when some resources don't have a value for the id property" do
      let(:incomplete_company) do
        instance_double('Company', changes: { name: 'Acme Corp' }, resource_name: 'companies', internal_id: nil)
      end
      let(:companies_including_incomplete) { (companies << incomplete_company) }

      it 'will raise an error' do
        batch = Hubspot::Batch.new(companies_including_incomplete, id_property: 'internal_id')
        expect{ batch.upsert }.to raise_error(Hubspot::ArgumentError)
      end
    end
  end
end
