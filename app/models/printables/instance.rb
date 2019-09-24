module Printables::Instance
  def print(printer_config, user)
    body_print = [printable_object(user)].compact
    return if Rails.configuration.printing_disabled || body_print.empty?
    if !printer_config
      raise 'No printer config provided'
    end
    printer_name = printer_name(printer_config)
    external_id = LabelTemplate.external_id_for_type(asset_type, barcode_type)
    raise 'Label template not found' unless external_id
    PMB::PrintJob.new(
      printer_name: printer_name,
      label_template_id: external_id,
      labels: {
        body: body_print
      }
    ).save
  end
end
