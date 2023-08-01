class AddDeprecatableToStep < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :steps, :superceded_by_id, :integer
  end
end
