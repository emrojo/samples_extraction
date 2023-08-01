class CreateKits < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :kits do |t|
      t.string :barcode, null: false
      t.integer :max_num_reactions
      t.integer :num_reactions_performed
      t.references :kit_type, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
