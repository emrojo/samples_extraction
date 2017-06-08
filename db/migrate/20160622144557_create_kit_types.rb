# frozen_string_literal: true
class CreateKitTypes < ActiveRecord::Migration
  def change
    create_table :kit_types do |t|
      t.string :name
      t.references :activity_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
