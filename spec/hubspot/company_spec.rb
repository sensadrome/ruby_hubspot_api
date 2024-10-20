# frozen_string_literal: true

# spec/hubspot/company_spec.rb
require 'spec_helper'
require 'hubspot/company'

RSpec.describe Hubspot::Company do
  context 'using a private app / access_token' do
    context 'without the required scope', configure_hubspot: :no_auth do
      describe 'retrieving the properties', cassette: 'companies/properties_no_scope' do
        it 'will raise an error' do
          expect { Hubspot::Company.properties }.to raise_error(Hubspot::OauthScopeError)
        end
      end
      describe 'retrieving a company', cassette: 'companies/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::Company.find(1) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

    context 'with the requied scope', configure_hubspot: true do
      let(:ts) { Time.now.strftime '%Y-%m-%d-%H-%M-%S' }

      context 'for existing contacts' do
        before(:all) { configure_hubspot! }

        # Will create a company for these tests and remove it at the end
        include_examples 'company_lifecycle', { name: 'ACME Example', domain: 'example.com' }

        let(:created_company) { @created_company }
        let(:company_id) { created_company.id }

        describe '.find', cassette: 'companies/find_by_id' do
          it 'retrieves a company by ID' do
            company = Hubspot::Company.find(company_id)
            expect(company).to be_a(Hubspot::Company)
            expect(company.id).to eq(company_id)
            expect(company.name).not_to be_nil
            expect(company.domain).not_to be_nil
          end
        end

        describe '#update and rollback', cassette: 'companies/patch_name' do
          it 'appends " updated" to the name of a company and rolls it back' do
            # Step 1: Retrieve the existing company and store the original name
            company = Hubspot::Company.find(company_id)
            original_name = company.name

            # Ensure we have the original name
            expect(original_name).not_to be_nil

            # Step 2: Append " updated" to the name and save it
            updated_name = "#{original_name} updated"
            company.name = updated_name
            company.save

            # Step 3: Retrieve the company again and verify the name was updated
            updated_company = Hubspot::Company.find(company_id)
            expect(updated_company.name).to eq(updated_name)

            # Step 4: Roll back the name to the original
            updated_company.name = original_name
            updated_company.save

            # Step 5: Verify the name was rolled back
            rolled_back_company = Hubspot::Company.find(company_id)
            expect(rolled_back_company.name).to eq(original_name)
          end
        end
      end

      describe '#create' do
        let(:test_company_name) { ENV.fetch('HUBSPOT_TEST_COMPANY_NAME', 'ACME Test Company') }
        let(:test_company_domain) { "example-#{ts}.com" }
        let(:company) { Hubspot::Company.new(name: test_company_name, domain: test_company_domain) }

        it 'will create a company in hubspot and return the id', cassette: 'companies/create' do
          company.save
          expect(company.id).to be_a(Integer)

          company_in_hubspot = Hubspot::Company.find(company.id)
          expect(company.name).to eq(company_in_hubspot.name)
          company.delete
        end
      end

      describe '#delete' do
        let(:test_company_name) { ENV.fetch('HUBSPOT_TEST_COMPANY_NAME', 'ACME Test Company') }
        let(:test_company_domain) { "example-#{ts}.com" }
        let(:company) { Hubspot::Company.new(name: test_company_name, domain: test_company_domain) }

        it 'will delete a company in Hubspot', cassette: 'companies/delete' do
          company.save
          expect(company.id).to be_a(Integer)
          company_in_hubspot = Hubspot::Company.find(company.id)
          expect(company.name).to eq(company_in_hubspot.name)

          company.delete
          expect { Hubspot::Company.find(company.id) }.to raise_error(Hubspot::NotFoundError)
        end
      end
    end
  end
end
