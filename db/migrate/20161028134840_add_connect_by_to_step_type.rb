class AddConnectByToStepType < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    ActiveRecord::Base.transaction { |_t| add_column :step_types, :connect_by, :string }
  end
end
