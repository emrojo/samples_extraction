# frozen_string_literal: true
class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string :uuid
      t.string :barcode
      t.timestamps null: false
    end
  end
end
