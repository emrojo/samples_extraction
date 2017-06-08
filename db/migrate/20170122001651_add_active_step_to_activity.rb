# frozen_string_literal: true
class AddActiveStepToActivity < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      add_column :activities, :active_step_id, :integer
      add_index :activities, :active_step_id
    end
  end
end
