class CreateLabPlates < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :lab_plates do |t|
      t.string :type

      t.timestamps null: false
    end
  end
end
