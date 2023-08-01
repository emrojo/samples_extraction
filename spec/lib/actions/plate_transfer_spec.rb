require 'rails_helper'
require 'actions/plate_transfer'

RSpec.describe Actions::PlateTransfer do
  context '#transfer_plates' do
    context 'when the source wells have a barcode' do
      it 'does not copy the barcode at destination' do
        source = create :asset
        tube = create(:asset, barcode: '1234')
        source.facts << create(:fact, predicate: 'contains', object_asset: tube)
        destination = create :asset
        updates = Actions::PlateTransfer.transfer_plates(source, destination)
        expect(updates.to_h[:add_facts].none? { |t| t[1] == 'barcode' }).to be(true)
      end
      it 'copies facts from source wells to destination wells' do
        source = create :asset
        well = create(:asset)
        well2 = create(:asset)

        source.facts << create(:fact, predicate: 'contains', object_asset: well)
        well.facts << create(:fact, predicate: 'a', object: 'Well')
        well.facts << create(:fact, predicate: 'location', object: 'A01')
        well.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
        well.facts << create(:fact, predicate: 'sample_common_name', object: 'species')

        source.facts << create(:fact, predicate: 'contains', object_asset: well2)
        well2.facts << create(:fact, predicate: 'a', object: 'Well')
        well2.facts << create(:fact, predicate: 'location', object: 'B01')
        well2.facts << create(:fact, predicate: 'concentration', object: '1.3')

        destination = create :asset
        updates = Actions::PlateTransfer.transfer_plates(source, destination)
        expect(updates.to_h[:add_facts].select { |t| t[1] == 'location' }.pluck(2)).to eq(%w[A01 B01])
        expect(updates.to_h[:add_facts].select { |t| t[1] == 'concentration' }.pluck(2)).to eq(['1.3'])
        expect(updates.to_h[:add_facts].select { |t| t[1] == 'sample_common_name' }.pluck(2)).to eq(['species'])
        expect(updates.to_h[:add_facts].select { |t| t[1] == 'a' }.pluck(2)).to eq(%w[Well Well])
      end
      it 'can copy facts with uuid values' do
        source = create :asset
        well = create(:asset)

        source.facts << create(:fact, predicate: 'contains', object_asset: well)
        well.facts << create(:fact, predicate: 'study', object: SecureRandom.uuid, literal: true)

        destination = create :asset
        updates = Actions::PlateTransfer.transfer_plates(source, destination)
        expect(updates.to_h[:set_errors].nil?).to eq(true)
      end
      it 'copies the aliquot type of the plate into the wells' do
        source = create :asset
        well = create(:asset)
        destination = create :asset

        well.facts << create(:fact, predicate: 'location', object: 'A01')
        source.facts << create(:fact, predicate: 'contains', object_asset: well)

        updates = FactChanges.new
        updates.add(destination, 'aliquotType', 'DNA')
        updates = Actions::PlateTransfer.transfer_plates(source, destination, updates)

        created_well = updates.to_h[:add_facts].find { |t| (t[1] == 'location') }[0]
        expect(updates.to_h[:add_facts].find { |t| (t[0] == created_well) && (t[1] == 'aliquotType') }[2]).to eq('DNA')
      end
      it 'does not copy ignored predicates' do
        source = create :asset
        well = create(:asset)
        destination = create :asset

        well.facts << create(:fact, predicate: 'location', object: 'A01')

        # pushedTo is an ignored predicate
        well.facts << create(:fact, predicate: 'pushedTo', object: 'Sequencescape')

        source.facts << create(:fact, predicate: 'contains', object_asset: well)

        updates = Actions::PlateTransfer.transfer_plates(source, destination, FactChanges.new)

        expect(updates.to_h[:add_facts].none? { |t| (t[1] == 'pushedTo') }).to be true
        expect(updates.to_h[:add_facts].any? { |t| (t[1] == 'location') }).to be true
      end
    end
  end
end
