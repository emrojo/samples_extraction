# frozen_string_literal: true
class CreateLabAliquots < ActiveRecord::Migration
  def change
    create_table :lab_aliquots do |t|
      t.string :type
      t.float :volume
      t.float :concentration

      t.timestamps null: false
    end
  end
end
