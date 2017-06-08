# frozen_string_literal: true
class AddStatusToOperations < ActiveRecord::Migration
  def change
    add_column :operations, :cancelled?, :boolean, default: false
  end
end
