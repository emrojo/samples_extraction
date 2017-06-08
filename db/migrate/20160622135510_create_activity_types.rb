# frozen_string_literal: true
class CreateActivityTypes < ActiveRecord::Migration
  def change
    create_table :activity_types do |t|
      t.string :name
      t.integer :superceded_by_id, null: true, index: true
      t.timestamps null: false
    end
  end
end
