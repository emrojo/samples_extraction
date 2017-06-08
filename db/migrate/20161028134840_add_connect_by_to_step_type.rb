# frozen_string_literal: true
class AddConnectByToStepType < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      add_column :step_types, :connect_by, :string
    end
  end
end
