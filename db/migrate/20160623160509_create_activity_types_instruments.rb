# frozen_string_literal: true
class CreateActivityTypesInstruments < ActiveRecord::Migration
  def change
    create_table :activity_types_instruments do |t|
      t.references :instrument, index: true, foreign_key: true
      t.references :activity_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
