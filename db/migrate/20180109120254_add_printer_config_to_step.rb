class AddPrinterConfigToStep < ActiveRecord::Migration # rubocop:todo Style/Documentation
  def change
    add_column :steps, :printer_config, :text
  end
end
