class AddActionToStepType < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :step_types, :step_action, :string
  end
end
