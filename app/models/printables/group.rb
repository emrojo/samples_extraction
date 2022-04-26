module Printables::Group
  def classify_for_printing(printer_config)
    template_cache = Hash.new { |store, types| store[types] = LabelTemplate.for_type(*types).external_id }

    assets.group_by do |asset|
      class_type = asset.class_type
      printer_name = printer_config[Printer.printer_type_for(class_type)]

      raise "There is no defined printer for asset with type #{class_type}" unless printer_name

      label_template_external_id = template_cache[[class_type, asset.barcode_type]]
      [printer_name, label_template_external_id]
    end
  end

  #
  # Print labels for the current Printables::Group (eg. Assets in an Asset
  # Group) using the default printers defined in printer_config
  #
  # @param printer_config [Hash] Typically returned bu the `User` maps a printer
  #                              type, 'Plate' or 'Tube' to a printer name.
  # @param _username [Void] Unused. Formerly the username.
  #
  # @return [Void]
  #
  def print(printer_config, _username = nil)
    return if Rails.configuration.printing_disabled

    classify_for_printing(printer_config).each do |(printer_name, external_id), assets|
      body_print = assets.filter_map(&:printable_object).reverse
      next if body_print.empty?

      PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: external_id,
        labels: { body: body_print }
      ).save
    end
  end
end
