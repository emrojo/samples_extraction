class CreateConditions < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :conditions do |t|
      t.references :condition_group, index: true, foreign_key: true
      t.string :predicate, null: false
      t.string :object, null: true
      t.integer :object_condition_group_id, default: nil, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
