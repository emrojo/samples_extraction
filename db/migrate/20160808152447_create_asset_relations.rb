# frozen_string_literal: true
class CreateAssetRelations < ActiveRecord::Migration
  def change
    create_table :asset_relations do |t|
      t.integer :subject_asset_id, index: true, foreign_key: true
      t.references :predicate, index: true, foreign_key: true
      t.integer :object_asset_id, index: true, foreign_key: true
      t.timestamps
    end
  end
end
