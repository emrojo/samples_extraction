class AddStartedAtAndCompletedAtToStep < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :steps, :started_at, :datetime
    add_column :steps, :finished_at, :datetime
  end
end
