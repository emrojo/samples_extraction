class ChangeHandlerToLongText < ActiveRecord::Migration[5.1]
  def change
    change_column :delayed_jobs, :handler, :text, limit: 4_294_967_295 # rubocop:disable Rails/ReversibleMigration
  end
end
