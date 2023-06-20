class AddUuidToAssetGroup < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :asset_groups, :uuid, :string, unique: true
  end
end
