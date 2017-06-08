# frozen_string_literal: true
class AddNamespaceToFactPredicate < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      add_column :facts, :ns_predicate, :string
    end
  end
end
