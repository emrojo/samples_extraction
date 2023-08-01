class CreateLabAliquots < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :lab_aliquots do |t|
      t.string :type
      t.float :volume
      t.float :concentration

      t.timestamps null: false
    end
  end
end
