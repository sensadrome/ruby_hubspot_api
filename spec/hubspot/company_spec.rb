# frozen_string_literal: true

# spec/hubspot/company_spec.rb
require 'spec_helper'
require 'hubspot/company'

# rubocop:disable Metrics/BlockLength
RSpec.describe Hubspot::Company do
  include_examples 'hubspot configuration'

  # Needs a valid company id for testing if you want to rerecord
  let(:company_id) { ENV.fetch('HUBSPOT_TEST_COMPANY_ID', 1).to_i }

  context 'using a private app with an access_token' do
    context 'without the required scope' do
      describe 'retrieving a company', cassette: 'companies/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::Company.find(1) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

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

    describe '#create' do
      let(:test_company_name) { ENV.fetch('HUBSPOT_TEST_COMPANY_NAME', 'ACME Test Company') }
      let(:company) { Hubspot::Company.new(name: test_company_name) }

      it 'will create a company in hubspot and return the id', cassette: 'companies/create' do
        company.save
        expect(company.id).to be_a(Integer)

        company_in_hubspot = Hubspot::Company.find(company.id)
        expect(company.name).to eq(company_in_hubspot.name)
      end
    end

    describe '#delete' do
      let(:test_company_id) { ENV.fetch('HUBSPOT_TEST_COMPANY_ID_DELETE', 666) }
      let(:company) { Hubspot::Company.find(test_company_id) }

      it 'will archive a company in hubspot', cassette: 'companies/delete' do
        expect(company.delete).to be true
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
