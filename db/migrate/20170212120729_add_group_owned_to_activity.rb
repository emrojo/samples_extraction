# frozen_string_literal: true
class AddGroupOwnedToActivity < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      add_column :asset_groups, :activity_owner_id, :integer
      add_column :asset_groups, :condition_group_id, :integer
    end
  end
end
