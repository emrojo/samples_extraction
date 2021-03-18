require 'rails_helper'

require Rails.root.to_s+'/script/runners/load_metadata'
require 'parsers/csv_metadata/csv_parser'

RSpec.describe 'LoadMetadata' do
  let(:content) { File.open('test/data/metadata.csv').read }
  let(:file) { create(:uploaded_file, data: content ) }
  let(:file_asset) { create :asset, uploaded_file: file }

  let(:positions) { TokenUtil.generate_positions(('A'..'H').to_a, ('1'..'12').to_a) }
  let(:wells) {
    96.times.map do |i|
      asset = FactoryBot.create(:asset)
      asset.facts << create(:fact, predicate: 'location', object: positions[i])
      asset.facts << create(:fact, predicate: 'a', object: 'Well')
      asset
    end
  }
  let(:rack) { create(:asset,
    barcode: 'DN1001001',
    facts: [
      create(:fact, predicate: 'a', object: 'TubeRack'),
      wells.map { |w| create(:fact, predicate: 'contains', object_asset_id: w.id) }
    ].flatten)}
  let(:instance) {
    LoadMetadata.new(asset_group: group)
  }
  context 'when it receives a metadata file' do
    let(:group) { create(:asset_group, assets: [rack, file_asset].flatten) }
    let(:added_triples) { instance.process.to_h[:add_facts] }
    it 'generates the number of changes for the specified assets in the file' do
      expect(added_triples.length).to eq(96*2)
    end
    it 'adds the right set of properties' do
      predicates = added_triples.map { |l| l[1] }.uniq
      expect(predicates).to eq(['data1', 'data2'])
    end
    it 'adds to the right number of assets' do
      assets = added_triples.map { |l| l[0] }.uniq
      expect(assets.count).to eq(96)
    end
  end
end
