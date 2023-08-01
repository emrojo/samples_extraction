class MigrateReasoningToTaskType < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    # StepType.for_reasoning.update_all(task_type: 'cwm')
  end
end
