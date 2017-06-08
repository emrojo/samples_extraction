# frozen_string_literal: true
class AddActionTypeToOperations < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      add_column :operations, :action_type, :string
    end
  end
end
