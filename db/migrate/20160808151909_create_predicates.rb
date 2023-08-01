class CreatePredicates < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :predicates do |t|
      t.string :name
      t.timestamps
    end
  end
end
