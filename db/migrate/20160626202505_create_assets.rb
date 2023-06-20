class CreateAssets < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :assets do |t|
      t.string :uuid
      t.string :barcode
      t.timestamps null: false
    end
  end
end
