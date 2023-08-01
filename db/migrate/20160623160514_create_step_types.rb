class CreateStepTypes < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :step_types do |t|
      t.string :name
      t.string :step_template, null: true
      t.binary :n3_definition
      t.integer :superceded_by_id, null: true, index: true
      t.boolean :for_reasoning, null: false, default: false
      t.timestamps null: false
    end
  end
end
