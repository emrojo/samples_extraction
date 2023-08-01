class AddMessagesTable < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    create_table :step_messages do |t|
      t.integer :step_id, null: false
      t.longtext :content

      t.timestamps null: false
    end
    add_index :step_messages, :step_id
  end
end
