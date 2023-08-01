require 'rails_helper'

RSpec.describe 'TractionFields' do
  shared_examples_for 'a method that converts from quoted to unquoted uuid' do
    let(:uuid) { SecureRandom.uuid }

    context 'when the uuid has been quoted for storing' do
      let(:store_uuid) { TokenUtil.quote(uuid) }
      it 'unquotes the uuid' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: predicate, object: store_uuid)

        expect(asset.send(method)).to eq(uuid)
      end
    end
    context 'when storing an unquoted uuid' do
      let(:store_uuid) { uuid }
      it 'returns the unquoted uuid' do
        asset = create(:asset)
        asset.facts << create(:fact, predicate: predicate, object: store_uuid)

        expect(asset.send(method)).to eq(uuid)
      end
    end
  end
  context '#sample_uuid' do
    let(:predicate) { 'sample_uuid' }
    let(:method) { :sample_uuid }
    it_behaves_like 'a method that converts from quoted to unquoted uuid'
  end
  context '#study_uuid' do
    let(:predicate) { 'study_uuid' }
    let(:method) { :study_uuid }
    it_behaves_like 'a method that converts from quoted to unquoted uuid'
  end
end
