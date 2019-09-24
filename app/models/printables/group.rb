module Printables::Group
  def classify_for_printing(assets, printer_config)
    assets.reduce({}) do |memo, asset|
      printer_name = asset.printer_name(printer_config)

      external_id = LabelTemplate.external_id_for_type(asset.asset_type, asset.barcode_type)
      raise 'Label template not found' unless external_id

      memo[printer_name] = {} unless memo[printer_name]
      memo[printer_name][external_id] = [] unless memo[printer_name][external_id]
      memo[printer_name][external_id].push(asset)

      memo
    end
  end

  def print(printer_config, user)
    print_assets(assets, printer_config, user)
  end

  def print_assets(assets, printer_config, user)
    return if Rails.configuration.printing_disabled

    classify_for_printing(assets, printer_config).each do |printer_name, info_for_template|
      info_for_template.each do |external_id, assets|
        body_print = assets.map{|a| a.printable_object(user)}.compact.reverse
        next if body_print.empty?
        PMB::PrintJob.new(
        printer_name:printer_name,
        label_template_id: external_id,
        labels:{body: body_print}
      ).save
      end
    end
  end

  module_function :print_assets
end
