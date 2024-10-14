# frozen_string_literal: true

RSpec.describe Hubspot::Resource do
  let(:subject) { described_class.new({}) } # Adjust as necessary

  it 'has a dynamic setter method to allow propreties to be set' do
    expect(subject.changes?).to be(false)
    expect(subject).not_to respond_to(:fake_property)
    subject.fake_property = 'fake value'
    expect(subject.changes?).to be(true)
    expect(subject).to respond_to(:fake_property)
  end
end
