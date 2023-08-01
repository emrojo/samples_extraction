class CreatePrinters < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :printers do |t|
      t.string :name, null: false, unique: true
      t.string :printer_type, null: true, unique: true
      t.boolean :default_printer, null: false, unique: true, default: false
      t.timestamps null: false
    end
  end
end
