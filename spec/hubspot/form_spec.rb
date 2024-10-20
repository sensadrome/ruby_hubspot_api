# frozen_string_literal: true

RSpec.describe Hubspot::Form, configure_hubspot: true do
  it 'inherits from Resource' do
    expect(described_class < Hubspot::Resource).to be true
  end

  let(:form_guid) { 'dummy-form-guid' }
  let(:fetch_form_page) { "https://api.hubapi.com/marketing/v3/forms/#{form_guid}" }

  describe '.find' do
    it 'hits the correct URL base for forms and processes response' do
      stub_request(:get, fetch_form_page)
        .to_return(body: { id: form_guid }.to_json, headers: { 'Content-Type' => 'application/json' })

      form = Hubspot::Form.find(form_guid)

      expect(form.id).to eq(form_guid)
      expect(WebMock).to have_requested(:get, fetch_form_page)
    end
  end

  context 'when intialised from the API' do
    let(:enquiry_form_response) { load_json(:enquiry_form) }

    before do
      stub_request(:get, fetch_form_page)
        .to_return(status: 200,
                   body: enquiry_form_response.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    let(:form) { Hubspot::Form.find(form_guid) }

    it 'is converted into a Hubspot::Form object' do
      expect(form).to be_a(Hubspot::Form)
    end
  end
end
