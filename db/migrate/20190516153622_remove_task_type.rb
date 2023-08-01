class RemoveTaskType < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    remove_column :step_types, :task_type
  end
end
