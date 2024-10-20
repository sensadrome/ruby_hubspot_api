# frozen_string_literal: true

RSpec.shared_examples 'company_lifecycle' do |properties, cassette_name|
  let(:created_company) { nil }

  before(:all) do
    VCR.use_cassette("lifecycle/companies/#{cassette_name}") do
      @created_company = Hubspot::Company.create(properties)
      expect(@created_company).not_to be_nil
      expect(@created_company.id).not_to be_nil
    end
  end

  after(:all) do
    # Clean up by deleting the company
    VCR.use_cassette("lifecycle/companies/#{cassette_name}_delete") do
      @created_company&.delete
    end
  end
end
