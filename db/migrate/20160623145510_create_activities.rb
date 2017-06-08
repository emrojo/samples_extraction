# frozen_string_literal: true
class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :activity_type, index: true, foreign_key: true
      t.references :instrument, index: true, foreign_key: true, null: true
      t.references :asset_group, index: true, foreign_key: true
      t.references :kit, index: true, foreign_key: true, null: true
      t.datetime :completed_at
      t.timestamps
    end
  end
end
