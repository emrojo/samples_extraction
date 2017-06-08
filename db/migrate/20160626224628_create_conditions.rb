# frozen_string_literal: true
class CreateConditions < ActiveRecord::Migration
  def change
    create_table :conditions do |t|
      t.references :condition_group, index: true, foreign_key: true
      t.string :predicate, null: false
      t.string :object, null: true
      t.integer :object_condition_group_id, default: nil, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
