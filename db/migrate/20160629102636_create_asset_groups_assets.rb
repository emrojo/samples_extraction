# frozen_string_literal: true
class CreateAssetGroupsAssets < ActiveRecord::Migration
  def change
    create_table :asset_groups_assets do |t|
      t.references :asset, index: true, foreign_key: true
      t.references :asset_group, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
