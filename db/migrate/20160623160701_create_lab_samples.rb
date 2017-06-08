# frozen_string_literal: true
class CreateLabSamples < ActiveRecord::Migration
  def change
    create_table :lab_samples do |t|
      t.string :type
      t.string :sanger_sample_id

      t.timestamps null: false
    end
  end
end
