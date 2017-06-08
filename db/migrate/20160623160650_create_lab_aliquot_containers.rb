# frozen_string_literal: true
class CreateLabAliquotContainers < ActiveRecord::Migration
  def change
    create_table :lab_aliquot_containers do |t|
      t.string :type

      t.timestamps null: false
    end
  end
end
