require 'rails_helper'
require 'actions/tube_transfer'

RSpec.describe 'Actions::TubeTransfer' do
  include Actions::TubeTransfer

  context '#transfer_tubes' do
    let(:source) { create :asset }
    let(:destination) { create :asset }
    let(:quoted_study_uuid) { TokenUtil.quote(SecureRandom.uuid) }
    let(:common_name) { 'common name' }
    before do
      source.facts << create(:fact, predicate: 'study_uuid', object: quoted_study_uuid)
      source.facts << create(:fact, predicate: 'sample_common_name', object: common_name)
    end
    it 'transfers study_uuid' do
      updates = transfer_tubes(source, destination)
      expect(updates.to_h[:add_facts].find { |t| t[1] == 'study_uuid' }[2]).to eq(quoted_study_uuid)
    end
    it 'transfers common name' do
      updates = transfer_tubes(source, destination)
      expect(updates.to_h[:add_facts].find { |t| t[1] == 'sample_common_name' }[2]).to eq(common_name)
    end
  end
end
