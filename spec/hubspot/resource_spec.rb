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

  describe '#all' do
    let(:collection) { described_class.all }
    it 'will return a PagedCollection' do
      expect(collection).to be_a(Hubspot::PagedCollection)
    end
    it 'will be a search collection' do
      expect(collection.send(:search_request?)).to be(true)
    end
  end

  describe '#where' do
    let(:collection) { described_class.where(email_contains: 'hubspot.com') }
    it 'will return a PagedCollection' do
      expect(collection).to be_a(Hubspot::PagedCollection)
    end
    it 'will be a search collection' do
      expect(collection.send(:search_request?)).to be(true)
    end
  end

  describe '#select' do
    let(:collection) { described_class.select(:email, :firstname, :lastname) }
    it 'will return a PagedCollection' do
      expect(collection).to be_a(Hubspot::PagedCollection)
    end
  end

  describe '.update' do
    let(:resource) { described_class.new }

    context 'when the resource is not saved in Hubspot' do
      it 'will raise an error' do
        expect { resource.update(firstname: 'Test') }.to raise_error(/not persisted/)
      end
    end

    context 'when the resource is saved in Hubspot', configure_hubspot: true do
      let(:resource) { described_class.new(id: 1) }
      before do
        stub_request(:patch, 'https://api.hubapi.com/crm/v3/objects/resources/1').to_return(status: 200)
      end

      it 'will not raise an error' do
        expect { resource.update(firstname: 'Test') }.not_to raise_error
      end
    end
  end

  describe '.update_attributes' do
    it 'expects a hash' do
      expect { subject.update_attributes('firstname') }.to raise_error(Hubspot::ArgumentError)
    end

    it 'will update the changes tracker on the resource' do
      subject.update_attributes(firstname: 'Test')
      expect(subject.firstname).to eq('Test')
      expect(subject.changes.keys).to include('firstname')
    end
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
