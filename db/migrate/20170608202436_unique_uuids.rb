# frozen_string_literal: true
class UniqueUuids < ActiveRecord::Migration
  def change
    add_index :assets, :uuid, unique: true
    remove_index :assets, :barcode
    add_index :assets, :barcode, unique: true
  end
end
