class CreateUsers < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :users do |t|
      t.string :login
      t.string :password
      t.string :barcode
      t.string :username
      t.string :fullname
      t.string :token
      t.string :role, default: 'operator'

      t.integer :tube_printer_id, default: nil, index: true, foreign_key: true
      t.integer :plate_printer_id, default: nil, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
