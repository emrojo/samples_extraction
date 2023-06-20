class CreateUploadedFiles < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    create_table :uploaded_files, force: true do |t|
      # t.references :asset_group, index: true, foreign_key: true
      t.integer :asset_id, index: true
      t.binary :data, limit: 10.megabyte
      t.string :filename
      t.string :content_type
      t.timestamps
    end
  end
end
