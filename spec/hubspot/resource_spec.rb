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

  describe '.save!' do
    let(:resource) { described_class.new(id: 1) }

    context 'when there are no changes' do
      it 'will raise an error' do
        expect { resource.save! }.to raise_error(Hubspot::NothingToDoError)
      end
    end

    context 'when there are changes' do
      before do
        subject.name = 'Ahsoka Tano'

        allow(subject).to receive(:save).and_return(true)
      end

      it 'will call save' do
        expect(subject.save!).to be(true)
        expect(subject).to have_received(:save)
      end
    end
  end
end
