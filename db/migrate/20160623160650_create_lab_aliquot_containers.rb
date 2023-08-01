class CreateLabAliquotContainers < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :lab_aliquot_containers do |t|
      t.string :type

      t.timestamps null: false
    end
  end
end
