class AddActionTypeToOperations < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    ActiveRecord::Base.transaction { |_t| add_column :operations, :action_type, :string }
  end
end
