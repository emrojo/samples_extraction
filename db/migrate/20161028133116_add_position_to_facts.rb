class AddPositionToFacts < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :facts, :position, :integer
  end
end
