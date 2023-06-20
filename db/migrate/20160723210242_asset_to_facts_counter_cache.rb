class AssetToFactsCounterCache < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :assets, :facts_count, :integer
  end
end
