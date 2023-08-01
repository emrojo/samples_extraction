class CreateAssetGroups < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :asset_groups do |t|
      t.timestamps null: false
    end
  end
end
