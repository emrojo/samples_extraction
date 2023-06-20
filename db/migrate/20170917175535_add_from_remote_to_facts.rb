class AddFromRemoteToFacts < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    ActiveRecord::Base.transaction do
      add_column :facts, :is_remote?, :boolean, default: false
      add_column :assets, :remote_digest, :string
    end
  end
end
