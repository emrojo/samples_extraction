require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  def create_well(location, sample, aliquot)
    well = create(:asset)
    well.facts << create(:fact, predicate: 'location', object: location)
    well.facts << create(:fact, predicate: 'supplier_sample_name', object: sample)
    well.facts << create(:fact, predicate: 'aliquotType', object: aliquot)
    well.facts << create(:fact, predicate: 'a', object: 'Well')
    well
  end

  context '#data_asset_display_for_plate' do
    let(:well) do
      w = create_well(location, sample, aliquot)
      w.update(barcode: barcode)
      w
    end
    let(:sample) { nil }
    let(:aliquot) { nil }
    let(:location) { nil }
    let(:barcode) { nil }

    let(:facts) { [create(:fact, predicate: 'contains', object_asset: well)] }
    let(:asset) { create :asset, facts: facts }
    context 'when the well has no location' do
      let(:location) { nil }
      it 'does not display the well' do
        obj = {}
        val = helper.data_asset_display_for_plate(asset.facts)

        expect(val).to eq(obj)
      end
    end
    context 'when the well has a location' do
      let(:location) { 'A1' }
      context 'when the well does not have a barcode or a sample' do
        let(:barcode) { nil }
        let(:sample) { nil }
        it 'does not display the well' do
          obj = {}
          val = helper.data_asset_display_for_plate(asset.facts)

          expect(val).to eq(obj)
        end
      end
      context 'when the well has a barcode or a sample' do
        let(:barcode) { 'S1234' }
        context 'when the well does not have a sample' do
          let(:sample) { nil }
          it 'displays an empty well' do
            val = helper.data_asset_display_for_plate(asset.facts)
            expect(val.keys).to eq(['A1'])
            expect(val.values.first[:cssClass]).to eq(helper.empty_well_aliquot_type)
          end
        end
        context 'when the well has a sample' do
          let(:sample) { 'sample1' }
          context 'when the well has an aliquot' do
            let(:aliquot) { 'DNA' }
            it 'displays the aliquot' do
              val = helper.data_asset_display_for_plate(asset.facts)
              expect(val.keys).to eq(['A1'])
              expect(val.values.first[:cssClass]).to eq('DNA')
            end
          end
          context 'when the well does not have an aliquot' do
            let(:aliquot) { nil }
            it 'displays unknown aliquot' do
              val = helper.data_asset_display_for_plate(asset.facts)
              expect(val.keys).to eq(['A1'])
              expect(val.values.first[:cssClass]).to eq(helper.unknown_aliquot_type)
            end
          end
        end
      end
    end
  end
end
