class AddKitTypeAbbreviation < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    add_column :kit_types, :abbreviation, :string
  end
end
