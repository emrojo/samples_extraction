# frozen_string_literal: true
class AddStateToStep < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      add_column :steps, :state, :string
    end
  end
end
