# frozen_string_literal: true
class CreateLabPlates < ActiveRecord::Migration
  def change
    create_table :lab_plates do |t|
      t.string :type

      t.timestamps null: false
    end
  end
end
