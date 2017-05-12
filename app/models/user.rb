class User < ActiveRecord::Base
  has_many :steps

  belongs_to :tube_printer, :class_name => 'Printer', :foreign_key => 'tube_printer_id'
  belongs_to :plate_printer, :class_name => 'Printer', :foreign_key => 'plate_printer_id'

  after_initialize :set_default_printers

  def set_default_printers
    update_attributes(
      :tube_printer => Printer.for_tube.for_default.first,
    )  if tube_printer.nil?
    update_attributes(
      :plate_printer => Printer.for_plate.for_default.first,
    )  if plate_printer.nil?
  end

  def tube_printer_name
    tube_printer.name if tube_printer
  end

  def plate_printer_name
    plate_printer.name if plate_printer
  end

  def generate_token
    update_attributes!(:token => MicroToken.generate(128))
    token
  end

  def clean_session
    update_attributes(:token => nil)
  end

  def has_role?(rolename)
    rolename.to_s == role
    return true
  end

  def session_info
    {:username => username, :fullname => fullname, :barcode => barcode, :role => role,
      :tube_printer_name => tube_printer_name, :plate_printer_name => plate_printer_name}
  end

  def printer_config
    {
      'Tube' => tube_printer_name,
      'Plate' => plate_printer_name
    }
  end


end
