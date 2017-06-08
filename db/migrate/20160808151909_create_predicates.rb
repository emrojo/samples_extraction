# frozen_string_literal: true
class CreatePredicates < ActiveRecord::Migration
  def change
    create_table :predicates do |t|
      t.string :name
      t.timestamps
    end
  end
end
