# frozen_string_literal: true

# spec/hubspot/contact_spec.rb
require 'spec_helper'
require 'hubspot/contact'

# rubocop:disable Metrics/BlockLength
RSpec.describe Hubspot::Contact do
  include_examples 'hubspot configuration'

  let(:contact_id) { ENV.fetch('HUBSPOT_TEST_CONTACT_ID', 1).to_i } # Hubspot sample contact id (if still present!)

  context 'using a private app with an access_token' do
    context 'without the required scope' do
      describe 'retrieving a contact', cassette: 'contacts/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::Contact.find(contact_id) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

    describe '.find', cassette: 'contacts/find_by_id' do
      it 'retrieves a contact by ID' do
        contact = Hubspot::Contact.find(contact_id)

        expect(contact).to be_a(Hubspot::Contact)
        expect(contact.id).to eq(contact_id)
        expect(contact.firstname).not_to be_nil
        expect(contact.lastname).not_to be_nil
        expect(contact.email).not_to be_nil
      end
    end

    describe '#update and rollback', cassette: 'contacts/patch_last_name' do
      it 'appends " updated" to the last name of a contact and rolls it back' do
        # Step 1: Retrieve the existing contact and store the original last name
        contact = Hubspot::Contact.find(contact_id)
        original_last_name = contact.lastname

        # Ensure we have the original name
        expect(original_last_name).not_to be_nil

        # Step 2: Append " updated" to the last name and save it
        updated_last_name = "#{original_last_name} updated"
        contact.lastname = updated_last_name
        contact.save

        # Step 3: Retrieve the contact again and verify the last name was updated
        updated_contact = Hubspot::Contact.find(contact_id)
        expect(updated_contact.lastname).to eq(updated_last_name)

        # Step 4: Roll back the last name to the original
        updated_contact.lastname = original_last_name
        updated_contact.save

        # Step 5: Verify the last name was rolled back
        rolled_back_contact = Hubspot::Contact.find(contact_id)
        expect(rolled_back_contact.lastname).to eq(original_last_name)
      end
    end

    describe '#search', cassette: 'contacts/search' do
      let(:search_domain) { ENV.fetch('HUBSPOT_SEARCH_TEST_DOMAIN', 'hubspot.com') }
      let(:limit) { ENV.fetch('HUBSPOT_SEARCH_LIMIT', 5).to_i }

      it 'searches contacts by email containing the domain' do
        search_params = { 'email_contains' => search_domain }
        results = Hubspot::Contact.search(query: search_params).first(limit)

        # Expect the result not to be empty
        expect(results).not_to be_empty

        # Expect the number of results to be no more than the limit
        expect(results.length).to be <= limit

        # Ensure each contact has an email containing the search domain
        results.each do |contact|
          expect(contact.email).to include(search_domain)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
