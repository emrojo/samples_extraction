# frozen_string_literal: true
class SetBarcodeIndexNotUnique < ActiveRecord::Migration
  def change
    remove_index :assets, :barcode
    add_index :assets, :barcode
  end
end
