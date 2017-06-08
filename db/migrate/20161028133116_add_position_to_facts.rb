# frozen_string_literal: true
class AddPositionToFacts < ActiveRecord::Migration
  def change
    add_column :facts, :position, :integer
  end
end
