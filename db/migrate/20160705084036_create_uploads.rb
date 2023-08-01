class CreateUploads < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    create_table :uploads do |t|
      t.references :step, index: true, foreign_key: true
      t.references :activity, index: true, foreign_key: true
      t.binary :data, limit: 10.megabyte
      t.string :filename
      t.string :content_type
      t.timestamps
    end
  end
end
