require 'rails_helper'
require Rails.root.to_s + '/script/runners/transfer_plate_to_plate'

RSpec.describe 'TransferPlateToPlate' do
  let(:sample_tube) { create(:asset) }
  def create_wells
    5.times.each_with_index.map do |i|
      create(
        :asset,
        facts: [
          create(:fact, predicate: 'a', object: 'Well'),
          create(:fact, predicate: 'location', object: "A0#{i + 1}")
        ]
      )
    end
  end

  def create_rack
    create(
      :asset,
      facts: [
        create(:fact, predicate: 'a', object: 'TubeRack'),
        create_wells.map { |w| create(:fact, predicate: 'contains', object_asset_id: w.id, literal: false) }
      ].flatten
    )
  end

  let(:instance) { TransferPlateToPlate.new(asset_group: group) }

  context 'when we have 2 plates defined in the group' do
    let(:group) { create(:asset_group, assets: [source_rack, destination_rack]) }
    let(:source_rack) { create_rack }
    let(:destination_rack) { create :asset }

    context 'when there is no transfer relation' do
      it 'does nothing' do
        expect(instance.process.to_h.keys.length).to eq(0)
      end
    end

    context 'when transferring between two plates' do
      before do
        source_rack.facts << create(:fact, predicate: 'transfer', object_asset_id: destination_rack.id)
        destination_rack.facts << create(:fact, predicate: 'transferredFrom', object_asset_id: source_rack.id)
      end

      let(:source_wells) { source_rack.facts.with_predicate('contains').map(&:object_asset) }
      let(:destination_wells) { destination_rack.facts.with_predicate('contains').map(&:object_asset) }

      context 'when the destination is an empty rack' do
        before do
          source_wells.each_with_index do |w, i|
            w.facts << create(:fact, predicate: 'sample_id', object: "Sample #{i}")
            w.facts << create(:fact, predicate: 'sample_tube', object_asset_id: sample_tube.id, literal: false)
          end
        end
        it 'transfers the contents of all wells' do
          added_facts = instance.process.to_h[:add_facts]
          destination_well_uuids = added_facts.select { |triple| triple[1] == 'contains' }.pluck(2)
          added_samples =
            added_facts.select { |triple| triple[1] == 'sample_id' }.map { |triple| [triple[0], triple[2]] }
          expect(added_samples).to eq(destination_well_uuids.each_with_index.map { |uuid, i| [uuid, "Sample #{i}"] })
          added_sample_tubes =
            added_facts.select { |triple| triple[1] == 'sample_tube' }.map { |triple| [triple[0], triple[2]] }
          expect(added_sample_tubes).to eq(destination_well_uuids.map { |uuid| [uuid, sample_tube.uuid] })
        end

        context 'with the aliquot defined at destination rack' do
          before { destination_rack.facts << create(:fact, predicate: 'aliquotType', object: 'DNA') }
          it 'transfers the aliquot across plates into rack and wells' do
            added_facts = instance.process.to_h[:add_facts]
            destination_well_uuids = added_facts.select { |triple| triple[1] == 'contains' }.pluck(2)
            added_aliquots =
              added_facts.select { |triple| triple[1] == 'aliquotType' }.map { |triple| [triple[0], triple[2]] }
            expect(added_aliquots.sort).to eq(destination_well_uuids.map { |uuid| [uuid, 'DNA'] }.sort)
          end
        end
      end

      context 'when the destination is a rack that already contains wells (well by well transfer)' do
        let(:destination_rack) { create_rack }

        before do
          source_wells.each_with_index do |w, i|
            w.facts << create(:fact, predicate: 'sample_id', object: "Sample #{i}")
            w.facts << create(:fact, predicate: 'sample_tube', object_asset_id: sample_tube.id, literal: false)
          end
        end
        it 'transfers the contents of all wells' do
          added_facts = instance.process.to_h[:add_facts]
          added_samples =
            added_facts.select { |triple| triple[1] == 'sample_id' }.map { |triple| [triple[0], triple[2]] }
          expect(added_samples).to eq(destination_wells.each_with_index.map { |w, i| [w.uuid, "Sample #{i}"] })
          added_sample_tubes =
            added_facts.select { |triple| triple[1] == 'sample_tube' }.map { |triple| [triple[0], triple[2]] }
          expect(added_sample_tubes).to eq(destination_wells.map { |w| [w.uuid, sample_tube.uuid] })
        end

        context 'with aliquot defined at source' do
          before { source_rack.facts << create(:fact, predicate: 'aliquotType', object: 'DNA') }
          it 'transfers the aliquot across plates into rack and wells' do
            added_facts = instance.process.to_h[:add_facts]
            added_aliquots =
              added_facts.select { |triple| triple[1] == 'aliquotType' }.map { |triple| [triple[0], triple[2]] }
            expect(added_aliquots.sort).to eq(
              [destination_rack.uuid].concat(destination_wells.map(&:uuid)).map { |uuid| [uuid, 'DNA'] }.sort
            )
          end
          context 'when the destination rack already contains an aliquot' do
            context 'when the aliquot is compatible' do
              before { destination_rack.facts << create(:fact, predicate: 'aliquotType', object: 'DNA') }

              it 'transfers the aliquot' do
                added_facts = instance.process.to_h[:add_facts]
                added_aliquots =
                  added_facts.select { |triple| triple[1] == 'aliquotType' }.map { |triple| [triple[0], triple[2]] }
                expect(added_aliquots.sort).to eq(
                  [destination_rack.uuid].concat(destination_wells.map(&:uuid)).map { |uuid| [uuid, 'DNA'] }.sort
                )
              end
            end
            context 'when aliquot is not compatible' do
              before { destination_rack.facts << create(:fact, predicate: 'aliquotType', object: 'RNA') }
              it 'fails all the transfer' do
                expect(instance.process.to_h[:set_errors]).not_to eq(nil)
              end
            end
          end
        end
      end
    end
  end
end
