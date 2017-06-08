# frozen_string_literal: true
module Printables::Instance
  def print(printer_config, user)
    body_print = [printable_object(user)].compact
    return if Rails.configuration.printing_disabled || body_print.empty?
    printer_name = printer_config[Printer.printer_type_for(class_type)]
    label_template = LabelTemplate.for_type(class_type, barcode_type).first
    PMB::PrintJob.new(
      printer_name: printer_name,
      label_template_id: label_template.external_id,
      labels: { body: body_print }
    ).save
  end
end
