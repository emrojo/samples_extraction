require './lib/print_my_barcode_job'
module Printables::Group # rubocop:todo Style/Documentation
  def classify_for_printing(printer_config)
    template_cache = Hash.new { |store, type| store[type] = LabelTemplate.for_type(type) }

    assets.group_by do |asset|
      class_type = asset.class_type
      printer_name = printer_config[Printer.printer_type_for(class_type)]

      raise "There is no defined printer for asset with type #{class_type}" unless printer_name

      label_template = template_cache[class_type]
      [printer_name, label_template]
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
  # @return [Printables::Summary] Summary object describing labels printed
  #
  def print(printer_config, _username = nil)
    return if Rails.configuration.printing_disabled

    Printables::Summary.new.tap do |summary|
      classify_for_printing(printer_config).each do |(printer_name, label_template), assets|
        body_print = assets.filter_map(&:printable_object).reverse
        next if body_print.empty?

        PrintMyBarcodeJob.new(printer_name: printer_name, label_template: label_template, labels: body_print).save
        summary.add_labels(printer_name, body_print.length)
      end
    end
  end
end
