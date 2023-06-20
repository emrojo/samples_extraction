class AddActivityRunningField < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :activities, :state, :string
  end
end
