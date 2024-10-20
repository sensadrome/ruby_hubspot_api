# frozen_string_literal: true

# spec/hubspot/contact_spec.rb
require 'spec_helper'
require 'hubspot/contact'

RSpec.describe Hubspot::Contact do
  # use the contact lifecyle shared example to ensure contact is present
  let(:test_contact) { @created_contact }

  # Hubspot sample contact email
  let(:contact_email) { ENV.fetch('HUBSPOT_TEST_CONTACT_EMAIL', 'test@example.org') }

  context 'using an access_token' do
    context 'without the required scope' do
      before(:all) { configure_hubspot_no_auth! }

      describe '.properties' do
        # Ensure another test has not left these in place..

        let(:properties) { Hubspot::Contact.properties }

        describe 'without the correct scope', cassette: 'contacts/properties_no_scope' do
          before { Hubspot::Contact.instance_variable_set('@properties', nil) }

          it 'will raise an error' do
            expect { properties }.to raise_error(Hubspot::OauthScopeError)
          end
        end
      end

      describe 'retrieving a contact', cassette: 'contacts/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::Contact.find(1) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

    context 'with the correct scope' do
      before(:all) { configure_hubspot! }

      describe '.properties' do
        let(:properties) { Hubspot::Contact.properties }

        it 'will return an array of properties', cassette: 'contacts/properties' do
          expect(properties).to be_a(Array)
          expect(properties).to all(be_a(Hubspot::Property))
        end

        describe 'when custom properties are defined' do
          let(:contact_properties) { load_json(:contact_properties) }
          let(:custom_contact_properties) { load_json(:custom_contact_properties) }
          let(:all_contact_properties) { contact_properties.concat(custom_contact_properties) }

          let(:custom_properties) { Hubspot::Contact.custom_properties }
          let(:read_only_properties) { Hubspot::Contact.read_only_properties }
          let(:updatable_properties) { Hubspot::Contact.updatable_properties }

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

          it 'can be filtered for read-only properties' do
            expect(properties).to be_a(Array)
            expect(properties).to all(be_a(Hubspot::Property))

            expect(read_only_properties).to be_a(Array)
            expect(read_only_properties).to all(be_a(Hubspot::Property))

            expect(read_only_properties.length).to be < properties.length
          end

          it 'can be filtered for updatable properties' do
            expect(properties).to be_a(Array)
            expect(properties).to all(be_a(Hubspot::Property))

            expect(updatable_properties).to be_a(Array)
            expect(updatable_properties).to all(be_a(Hubspot::Property))

            expect(updatable_properties.length).to be < properties.length
          end

          describe 'a property' do
            let(:property) { Hubspot::Contact.property('hubspot_owner_id') }
            it 'can be called from .property' do
              expect(property).to be_a(Hubspot::Property)
            end
          end
        end
      end

      describe '.find_by' do
        include_examples 'contact_lifecycle', {
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User'
        }, 'find_by'

        it 'retrieves a contact by email', cassette: 'contacts/find_test_user_by_email' do
          contact = Hubspot::Contact.find_by('email', 'test@example.com')

          expect(contact).to be_a(Hubspot::Contact)
          expect(contact.id).to eq(test_contact.id)
          expect(contact.firstname).to eq('Test')
          expect(contact.lastname).to eq('User')
          expect(contact.email).to eq('test@example.com')
        end
      end

      describe '.find_by_token' do
        let(:contact_by_utk_page) { "https://api.hubapi.com/contacts/v1/contact/utk/#{token}/profile" }
        let(:token) { 'hubspotutk' }
        let(:response_data) { load_json('contact_by_utk') }

        # let(:contact_id) { 1 }
        # let(:contact_fetch_page) { "/crm/v3/objects/contacts/#{contact_id}" }

        before do
          stub_request(:get, contact_by_utk_page)
            .with(query: hash_including({}))
            .to_return(status: 200, body: response_data.to_json, headers: { 'Content-Type' => 'application/json' })
        end

        it 'makes the right request' do
          contact = Hubspot::Contact.find_by_token(token, properties: %w[email firstname lastname])
          expect(contact).to be_a(Hubspot::Contact)
          expect(WebMock).to have_requested(:get, contact_by_utk_page).with(query: hash_including({}))
        end
      end

      describe '.find' do
        include_examples 'contact_lifecycle', {
          email: 'test@example.org',
          firstname: 'Test',
          lastname: 'User'
        }, 'find'

        it 'retrieves a contact by ID', cassette: 'contacts/find_by_id' do
          contact = Hubspot::Contact.find(test_contact.id)

          expect(contact).to be_a(Hubspot::Contact)
          expect(contact.firstname).to eq(test_contact.firstname)
          expect(contact.lastname).to eq(test_contact.lastname)
          expect(contact.email).to eq(test_contact.email)
        end
      end

      describe '#save and rollback', cassette: 'contacts/patch_last_name' do
        include_examples 'contact_lifecycle', {
          email: 'patchme@example.com',
          firstname: 'Patch',
          lastname: 'Meyup'
        }, 'patch_last_name'

        it 'appends " updated" to the last name of a contact and rolls it back' do
          # Step 1: Retrieve the existing contact and store the original last name
          contact = Hubspot::Contact.find(test_contact.id)
          original_last_name = contact.lastname

          # Ensure we have the original name
          expect(original_last_name).not_to be_nil

          # Step 2: Append " updated" to the last name and save it
          updated_last_name = "#{original_last_name} updated"
          contact.lastname = updated_last_name
          contact.save

          # Step 3: Retrieve the contact again and verify the last name was updated
          updated_contact = Hubspot::Contact.find(test_contact.id)
          expect(updated_contact.lastname).to eq(updated_last_name)

          # Step 4: Roll back the last name to the original
          updated_contact.lastname = original_last_name
          updated_contact.save

          # Step 5: Verify the last name was rolled back
          rolled_back_contact = Hubspot::Contact.find(test_contact.id)
          expect(rolled_back_contact.lastname).to eq(original_last_name)
        end
      end

      describe '#list.first' do
        let(:props) { %w[email firstname lastname] }

        context 'without specifying properties', cassette: 'contacts/list_first_no_props' do
          let(:contact) { Hubspot::Contact.list.first }

          it 'should return a single instance of a Contact' do
            expect(contact).to be_a(Hubspot::Contact)
          end

          it 'should return a contact with the default properties' do
            expect(contact.properties.keys.sort).to eq(props)
          end
        end

        context 'when specifying properties', cassette: 'contacts/list_first_with_props' do
          let(:less_props) { props.take(props.length - 1) }

          let(:contact) { Hubspot::Contact.list(properties: less_props).first }

          it 'should return a single instance of a Contact' do
            expect(contact).to be_a(Hubspot::Contact)
          end

          it 'should return a contact with the default properties' do
            expect(contact.properties.keys.sort).to eq(less_props)
          end
        end
      end

      describe '#search', configure_hubspot: true do
        context 'with invalid params' do
          it 'will only accept a string or a hash' do
            expect { Hubspot::Contact.search(query: 1) }.to raise_error(Hubspot::ArgumentError)
          end
        end

        context 'with valid params', configure_hubspot: true do
          include_examples 'batch_contacts_lifecycle', 10, 'example.org', 'search'
          let(:created_batch) { @created_batch }

          let(:limit) { 5 }
          let(:results) { Hubspot::Contact.search(query: search_params).first(limit) }

          context 'when searching using search parameters as a hash' do
            context 'by email contains', cassette: 'contacts/search' do
              let(:search_domain) { 'example.org' }
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
              let(:test_email) { created_batch.contacts.first.email }

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
            let(:search_params) { 'Test' }

            it 'searches contacts matching the query in any field' do
              # Expect the result not to be empty
              expect(results).not_to be_empty

              # Expect the number of results to be no more than the limit
              expect(results.length).to be <= limit
            end
          end
        end
      end
    end

    describe 'when a property is updated' do
      before(:all) { configure_hubspot! }
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

    describe 'when intialised with email property' do
      let(:contact) { Hubspot::Contact.new(email: 'leya@rebelaliance.org') }

      it 'will respond to .email' do
        expect(contact).to respond_to(:email)
      end

      it 'will not respond_to .firstname' do
        expect { contact.firstname }.to raise_error(NoMethodError)
      end
    end
  end
end
