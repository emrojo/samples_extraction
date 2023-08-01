class AddStiToStep < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :steps, :sti_type, :string
  end
end
