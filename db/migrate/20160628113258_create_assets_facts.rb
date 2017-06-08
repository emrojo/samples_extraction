# frozen_string_literal: true
class CreateAssetsFacts < ActiveRecord::Migration
  def change
    create_table :assets_facts do |t|
      t.references :asset, index: true, foreign_key: true
      t.references :fact, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
