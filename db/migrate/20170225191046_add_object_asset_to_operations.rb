class AddObjectAssetToOperations < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :operations, :object_asset_id, :integer
  end
end
