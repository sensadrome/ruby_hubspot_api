# frozen_string_literal: true

RSpec.shared_examples 'contact_lifecycle' do |properties, cassette_name|
  let(:created_contact) { nil }

  before(:example) do
    VCR.use_cassette("lifecycle/contacts/#{cassette_name}") do
      @created_contact = Hubspot::Contact.create(properties)
      expect(@created_contact).not_to be_nil
      expect(@created_contact.id).not_to be_nil
    end
  end

  after(:example) do
    # Clean up by deleting the contact
    VCR.use_cassette("lifecycle/contacts/#{cassette_name}_delete") do
      @created_contact&.delete
    end
  end
end
