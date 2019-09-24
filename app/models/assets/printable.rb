module Assets::Printable

  def pmb_template_type

  end

  def printable_object(username = 'unknown')
    return nil if barcode.nil?
    if (kind_of_plate?)
      return {
        :label => {
          :barcode => line_for(:barcode),
          :top_left => line_for(:todays_date),
          :top_right => line_for([:purpose, :aliquot, :position_value]),
          :bottom_right => line_for([:study, :barcode_sequencescaped]),
          :bottom_left => line_for(:barcode)
        }
      }
    end
    return {:label => {
      :barcode => line_for(:barcode),
      :barcode2d => line_for(:barcode),
      :top_line => line_for(:barcode),
      :bottom_line => line_for([:purpose, :aliquot, :position_value])
      }
    }
  end

  def line_for(fields)
    fields.map do |field|
      send(field)
    end.compact.join(' ').strip
  end

  def todays_date
    DateTime.now.strftime('%d/%b/%y')
  end

  def printer_name(printer_config)
    printer_config[Printer.printer_type_for(asset_type)]
  end


end
