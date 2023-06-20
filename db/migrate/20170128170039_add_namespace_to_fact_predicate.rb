class AddNamespaceToFactPredicate < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    ActiveRecord::Base.transaction { |_t| add_column :facts, :ns_predicate, :string }
  end
end
