class SetBarcodeIndexNotUnique < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    remove_index :assets, :barcode
    add_index :assets, :barcode
  end
end
