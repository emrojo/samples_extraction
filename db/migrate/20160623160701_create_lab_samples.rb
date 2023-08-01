class CreateLabSamples < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :lab_samples do |t|
      t.string :type
      t.string :sanger_sample_id

      t.timestamps null: false
    end
  end
end
