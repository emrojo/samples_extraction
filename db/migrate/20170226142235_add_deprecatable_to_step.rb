# frozen_string_literal: true
class AddDeprecatableToStep < ActiveRecord::Migration
  def change
    add_column :steps, :superceded_by_id, :integer
  end
end
