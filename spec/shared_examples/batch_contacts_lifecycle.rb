# frozen_string_literal: true

RSpec.shared_examples 'batch_contacts_lifecycle' do |count, domain, cassette_name|
  let(:created_batch) { nil }

  before(:all) do
    Hubspot.logger.info "Creating Batch #{cassette_name}"
    contacts = Array.new(count) do |seq|
      props = { firstname: "Test #{seq + 1}", lastname: 'User', email: "test#{seq + 1}@#{domain}" }
      Hubspot::Contact.new(props)
    end

    VCR.use_cassette("lifecycle/contacts/batches/#{cassette_name}") do
      @created_batch = Hubspot::Batch.new(contacts)
      @created_batch.create
      break unless VCR.current_cassette.recording?

      wait_per_contact = ENV.fetch('HUBSPOT_BATCH_WAIT_PER_RESOURCE', 1).to_i
      batch_wait = wait_per_contact * count
      Hubspot.logger.warn "Wating for Batch #{cassette_name} (#{batch_wait} seconds)"
      sleep(batch_wait)
    end
  end

  after(:all) do
    # Clean up by deleting the contact
    VCR.use_cassette("lifecycle/contacts/batches/#{cassette_name}_archive") do
      @created_batch&.archive
    end
    Hubspot.logger.info "Removed Batch #{cassette_name}"
  end
end
