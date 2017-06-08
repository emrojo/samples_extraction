# frozen_string_literal: true
class CreateInstruments < ActiveRecord::Migration
  def change
    create_table :instruments do |t|
      t.string :barcode
      t.string :name
      t.timestamps null: false
    end
  end
end
