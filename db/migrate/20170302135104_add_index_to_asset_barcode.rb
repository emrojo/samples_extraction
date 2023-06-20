class AddIndexToAssetBarcode < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_index :assets, :barcode, unique: true
  end
end
