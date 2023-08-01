# frozen_string_literal: true

# Ensures the uuid column is required and indexed
# Ideally this would be a unique constraint, but there are current data integrity
# issues preventing this.
class IndexAndConstrainUuid < ActiveRecord::Migration[5.2]
  def change
    change_column_null :assets, :uuid, false
    add_index :assets, :uuid
  end
end
