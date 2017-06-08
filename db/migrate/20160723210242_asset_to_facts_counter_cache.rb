# frozen_string_literal: true
class AssetToFactsCounterCache < ActiveRecord::Migration
  def change
    add_column :assets, :facts_count, :integer
  end
end
