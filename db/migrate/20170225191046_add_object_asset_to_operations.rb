# frozen_string_literal: true
class AddObjectAssetToOperations < ActiveRecord::Migration
  def change
    add_column :operations, :object_asset_id, :integer
  end
end
