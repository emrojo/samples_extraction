require 'rails_helper'
RSpec.describe AssetGroup, type: :model do
  context '#update_with_assets' do
    let(:existing_assets) { create_list :asset, 3 }
    let(:new_assets) { create_list :asset, 2 }
    let(:group) { create(:asset_group, assets: existing_assets) }
    before { allow(group).to receive(:refresh!).and_return(true) }
    it 'adds new assets to the group' do
      expect { group.update_with_assets(existing_assets.concat(new_assets)) }.to change { Operation.count }.by(
        2
      ).and change { group.assets.count }.by(2)
    end
    it 'removes assets not present anymore in the group' do
      expect { group.update_with_assets(new_assets) }.to change { Operation.count }.by(5).and change {
                                         group.assets.count
                                       }.by(-1)
    end

    it 'refreshes the new added assets' do
      group.update_with_assets(existing_assets.concat(new_assets))
      expect(group).to have_received(:refresh!)
    end
  end
end
