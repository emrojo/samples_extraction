class AddJobIdToStep < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :steps, :job_id, :integer
  end
end
