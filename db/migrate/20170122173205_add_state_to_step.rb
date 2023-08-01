class AddStateToStep < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    ActiveRecord::Base.transaction { |_t| add_column :steps, :state, :string }
  end
end
