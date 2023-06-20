require 'rails_helper'

RSpec.describe Fact do
  context 'when it defines a literal' do
    it 'can store a uuid' do
      fact = build(:fact, predicate: 'pred', object: SecureRandom.uuid, object_asset_id: nil, literal: true)
      expect(fact).to be_valid
    end
    it 'can store a string' do
      fact = build(:fact, predicate: 'pred', object: 'str', object_asset_id: nil, literal: true)
      expect(fact).to be_valid
    end
  end
  context 'when defines a relation' do
    let(:asset) { create :asset }
    it 'cannot store anything without object_asset_id defined' do
      fact = build(:fact, predicate: 'pred', object: 'str', object_asset_id: asset, literal: false)
      expect(fact).not_to be_valid
    end
    it 'cannot store any string if object_asset_id defined' do
      fact = build(:fact, predicate: 'pred', object: 'str', object_asset_id: asset, literal: false)
      expect(fact).not_to be_valid
    end
  end
end
