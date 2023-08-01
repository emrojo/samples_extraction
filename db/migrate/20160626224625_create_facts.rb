class CreateFacts < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :facts do |t|
      t.references :asset, index: true, foreign_key: true
      t.string :predicate, null: false
      t.string :object, null: true
      t.boolean :literal, default: true, null: false
      t.integer :object_asset_id, default: nil, index: true, foreign_key: true
      t.integer :to_add_by, default: nil, null: true
      t.integer :to_remove_by, default: nil, null: true
      t.boolean :up_to_date, default: false, null: false
      t.timestamps null: false
    end
  end
end
