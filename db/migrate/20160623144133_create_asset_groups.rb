# frozen_string_literal: true
class CreateAssetGroups < ActiveRecord::Migration
  def change
    create_table :asset_groups do |t|
      t.timestamps null: false
    end
  end
end
