require 'rails_helper'
RSpec.describe Assets::FactsManagement do
  context '#first_value_for' do
    it 'returns the first object value for an asset predicate' do
      asset = create :asset
      asset.facts << create(:fact, predicate: 'aliquotType', object: 'DNA')
      asset.facts << create(:fact, predicate: 'aliquotType', object: 'RNA')

      expect(asset.first_value_for('aliquotType')).to eq('DNA')
    end

    it 'returns nil if there is not any predicates that match the condition' do
      asset = create :asset
      asset.facts << create(:fact, predicate: 'aliquotType2', object: 'DNA')
      asset.facts << create(:fact, predicate: 'aliquotType2', object: 'RNA')

      expect(asset.first_value_for('aliquotType')).to eq(nil)
    end

    it 'returns nil if there is not facts' do
      asset = create :asset

      expect(asset.first_value_for('aliquotType')).to eq(nil)
    end

    it 'returns nil if it is a relation instead of a object alue' do
      asset = create :asset
      w1 = create :asset
      asset.facts << create(:fact, predicate: 'contains', object_asset: w1)

      expect(asset.first_value_for('contains')).to eq(nil)
    end
  end
end
