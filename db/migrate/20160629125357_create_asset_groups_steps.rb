# frozen_string_literal: true
class CreateAssetGroupsSteps < ActiveRecord::Migration
  def change
    create_table :asset_groups_steps do |t|
      t.references :asset_group, index: true, foreign_key: true
      t.references :step, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
