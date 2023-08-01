class AddOutputToSteps < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :steps, :output, :longtext
  end
end
