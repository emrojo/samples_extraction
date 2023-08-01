class CreateInstruments < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :instruments do |t|
      t.string :barcode
      t.string :name
      t.timestamps null: false
    end
  end
end
