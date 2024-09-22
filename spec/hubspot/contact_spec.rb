# frozen_string_literal: true

# spec/hubspot/contact_spec.rb
require 'spec_helper'
require 'hubspot/contact'

RSpec.describe Hubspot::Contact do
  include_examples 'hubspot configuration'

  # Hubspot sample contact id (if still present!)
  let(:contact_id) { ENV.fetch('HUBSPOT_TEST_CONTACT_ID', 1).to_i }
  # Hubspot sample contact email
  let(:contact_email) { ENV.fetch('HUBSPOT_TEST_CONTACT_EMAIL', 'emailmaria@hubspot.com') }

  context 'using a private app with an access_token' do
    describe '.properties' do
      let(:properties) { Hubspot::Contact.properties }

      describe 'without the correct scope', cassette: 'contacts/properties_no_scope' do
        it 'will raise an error' do
          expect { properties }.to raise_error(Hubspot::OauthScopeError)
        end
      end

      context 'with the correct scope' do
        it 'will return an array of properties', cassette: 'contacts/properties' do
          expect(properties).to be_a(Array)
          expect(properties).to all(be_a(Hubspot::Property))
        end

        describe 'when customer properties are defined' do
          let(:contact_properties) { load_json(:contact_properties) }
          let(:custom_contact_properties) { load_json(:custom_contact_properties) }
          let(:all_contact_properties) { contact_properties.concat(custom_contact_properties) }

          let(:custom_properties) { Hubspot::Contact.custom_properties }

          let(:fetch_properties_page) { 'https://api.hubapi.com/crm/v3/objects/properties/contacts' }

          before do
            stub_request(:get, fetch_properties_page)
              .to_return(status: 200,
                         body: all_contact_properties.to_json,
                         headers: { 'Content-Type' => 'application/json' })
          end

          it 'can be filtered for custom properties' do
            expect(properties).to be_a(Array)
            expect(properties).to all(be_a(Hubspot::Property))

            expect(custom_properties).to be_a(Array)
            expect(custom_properties).to all(be_a(Hubspot::Property))

            expect(custom_properties.length).to be < properties.length
          end

          describe 'a property' do
            let(:property) { Hubspot::Contact.property('enquiry_status') }
            it 'can be called from .property' do
              expect(property).to be_a(Hubspot::Property)
            end
          end
        end
      end
    end

    context 'without the required scope' do
      describe 'retrieving a contact', cassette: 'contacts/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::Contact.find(contact_id) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

    describe '.find_by', cassette: 'contacts/find_by_email' do
      it 'retrieves a contact by email' do
        contact = Hubspot::Contact.find_by('email', contact_email)

        expect(contact).to be_a(Hubspot::Contact)
        expect(contact.id).to eq(contact_id)
        expect(contact.firstname).not_to be_nil
        expect(contact.lastname).not_to be_nil
        expect(contact.email).not_to be_nil
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

    describe '#save and rollback', cassette: 'contacts/patch_last_name' do
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

    describe '#search' do
      it 'will only accept a string or a hash' do
        expect { Hubspot::Contact.search(query: 1) }.to raise_error(Hubspot::ArgumentError)
      end

      let(:search_domain) { ENV.fetch('HUBSPOT_SEARCH_TEST_DOMAIN', 'hubspot.com') }
      let(:limit) { ENV.fetch('HUBSPOT_SEARCH_LIMIT', 5).to_i }
      let(:results) { Hubspot::Contact.search(query: search_params).first(limit) }

      context 'when searching using search parameters as a hash' do
        context 'by email contains', cassette: 'contacts/search' do
          let(:search_params) { { 'email_contains' => search_domain } }

          it 'matches the terms specified' do
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

        context 'by email equals', cassette: 'contacts/search_by_email' do
          let(:test_email) { ENV.fetch('HUBSPOT_TEST_CONTACT_EMAIL', 'test@hubspot.com') }
          let(:search_params) { { 'email' => test_email } }

          it 'matches the terms specified' do
            # Expect the result not to be empty
            expect(results).not_to be_empty

            # Expect the number of results to be no more than the limit
            expect(results.length).to be <= limit

            # Ensure each contact has an email containing the search domain
            results.each do |contact|
              # strictly speaking the search will return a contact with any email mathching...
              expect(contact.email).to eq(test_email)
            end
          end
        end
      end

      context 'when searching using a string for the query', cassette: 'contacts/search_by_string' do
        let(:search_params) { 'hubspot' }

        it 'searches contacts matching the query in any field' do
          # Expect the result not to be empty
          expect(results).not_to be_empty

          # Expect the number of results to be no more than the limit
          expect(results.length).to be <= limit
        end
      end
    end

    describe '#update and rollback', cassette: 'contacts/patch_last_name' do
      it 'appends " updated" to the last name of a contact using the update method' do
        # Step 1: Retrieve the existing contact and store the original last name
        contact = Hubspot::Contact.find(contact_id)
        original_last_name = contact.lastname

        # Ensure we have the original name
        expect(original_last_name).not_to be_nil

        # Step 2: Append " updated" to the last name and save it
        updated_last_name = "#{original_last_name} updated"
        contact.update(lastname: updated_last_name)

        expect(contact.lastname).to eq(updated_last_name)
        expect(contact.changes).to be_empty
        expect(contact.properties['lastname']).to eq(updated_last_name)

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
  end

  describe 'when a property is updated' do
    let(:contact_fetch_page) { 'https://api.hubapi.com/crm/v3/objects/contacts/1' }
    let(:contact_json) do
      '{"id":"1","properties":{"email":"luke@jedi.org","firstname":"Luke","hs_object_id":"1","lastname":"Skywalker"}}'
    end
    let(:contact) { Hubspot::Contact.find(1) }

    before do
      # Stub the request to return a 429 rate-limit response (with immediate retry ;)
      stub_request(:get, contact_fetch_page)
        .to_return(status: 200, body: contact_json, headers: { 'Content-Type' => 'application/json' })
      contact.email = 'luke@sith.net'
    end

    it 'willl track the change' do
      expect(contact.changes).to have_key('email')
    end

    describe 'and then set back to the original' do
      it 'will empty the changes tracker' do
        contact.email = 'luke@jedi.org'
        expect(contact.changes).to be_empty
      end
    end
  end
end
