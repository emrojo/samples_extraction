require './lib/print_my_barcode_job'

module Printables::Instance # rubocop:todo Style/Documentation
  #
  # Print labels for the current Printables::Instance (eg. Asset) using the
  # default printers defined in printer_config
  #
  # @param printer_config [Hash] Typically returned bu the `User` maps a printer
  #                              type, 'Plate' or 'Tube' to a printer name.
  # @param _username [Void] Unused. Formerly the username.
  #
  # @return [Void]
  #
  def print(printer_config)
    body_print = [printable_object].compact
    return if Rails.configuration.printing_disabled || body_print.empty?
    raise 'No printer config provided' if !printer_config

    printer_name = printer_config[Printer.printer_type_for(class_type)]
    label_template = LabelTemplate.for_type(class_type)
    PrintMyBarcodeJob.new(printer_name: printer_name, label_template: label_template, labels: body_print).save
  end
end
