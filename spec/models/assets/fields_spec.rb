require 'rails_helper'

RSpec.describe 'Assets::Fields' do
  context '#asset_type (facts with predicate: "a")' do
    context 'when the asset contains one asset_type fact' do
      it 'returns that asset type' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
        expect(asset.asset_type).to eq('TubeRack')
      end
    end
    context 'when the asset contains more than one fact' do
      it 'returns the asset type that has priority as defined in configuration' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: 'a', object: 'Tube')
        asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
        expect(asset.asset_type).to eq('TubeRack')
      end
    end
    context 'when the asset does not contain any fact' do
      it 'returns nil' do
        asset = create(:asset)
        expect(asset.asset_type).to eq(nil)
      end
    end
  end

  context '#asset_types' do
    it 'returns the list of asset types (facts with predicate "a")' do
      asset = create(:asset)
      asset.facts << create(:fact, predicate: 'a', object: 'Tube')
      asset.facts << create(:fact, predicate: 'a', object: 'TubeRack')
      expect(asset.asset_types).to eq(['Tube', 'TubeRack'])
    end
  end

  context '#wells' do
    it 'returns the list of wells (facts with predicate "contains")' do
      asset = create(:asset)
      w1 = create(:asset)
      w2 = create(:asset)
      asset.facts << create(:fact, predicate: 'contains', object_asset: w1)
      asset.facts << create(:fact, predicate: 'contains', object_asset: w2)
      expect(asset.wells).to eq([w1,w2])
    end
  end

  context '#short_description' do
    context 'when the asset has a barcode' do
      it 'returns a string with a short description of the asset with the barcode' do
        asset = create(:asset, barcode: '1234')
        asset.facts << create(:fact, predicate: 'a', object: 'Tube')
        asset.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
        expect(asset.short_description).to eq("DNA Tube 1234")
      end
    end
    context 'when the asset does not have a barcode' do
      it 'returns a string with a short description of the asset without the barcode' do
        asset = create(:asset, barcode: nil)
        asset.facts << create(:fact, predicate: 'a', object: 'Tube')
        asset.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
        expect(asset.short_description).to eq("DNA Tube #")
      end
    end
  end
end
