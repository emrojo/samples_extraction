# frozen_string_literal: true
class CreateActivityTypeCompatibilities < ActiveRecord::Migration
  def change
    create_table :activity_type_compatibilities do |t|
      t.references :asset, index: true, foreign_key: true
      t.references :activity_type, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
