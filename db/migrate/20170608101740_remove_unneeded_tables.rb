# frozen_string_literal: true
class RemoveUnneededTables < ActiveRecord::Migration
  def change
    drop_table :asset_groups_steps
    drop_table :asset_relations
    drop_table :assets_facts
    drop_table :lab_aliquot_containers
    drop_table :lab_aliquots
    drop_table :lab_plates
    drop_table :lab_samples
    drop_table :predicates
  end
end
