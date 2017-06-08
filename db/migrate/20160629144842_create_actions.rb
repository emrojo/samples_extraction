# frozen_string_literal: true
class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.string :action_type, null: false
      t.references :step_type, index: true, foreign_key: true
      t.integer :subject_condition_group_id, index: true, foreign_key: true
      t.string :predicate, null: false
      t.string :object, null: true
      t.integer :object_condition_group_id, index: true
      t.timestamps null: false
    end
  end
end
