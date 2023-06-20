class CreateActivityTypeStepTypes < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :activity_type_step_types do |t|
      t.references :activity_type, index: true, foreign_key: true
      t.references :step_type, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
