class CreateSteps < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :steps do |t|
      t.references :step_type, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.date :completion_date
      t.references :activity, index: true, foreign_key: true
      t.references :asset_group, index: true, foreign_key: true
      t.integer :created_asset_group_id, default: nil, index: true, foreign_key: true
      t.boolean :in_progress?, default: false
      t.timestamps
    end
  end
end
