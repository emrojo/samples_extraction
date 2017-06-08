# frozen_string_literal: true
class Printer < ActiveRecord::Base
  scope :for_tube, ->() { where(printer_type: 'Tube') }
  scope :for_plate, ->() { where(printer_type: 'Plate') }
  scope :for_default, ->() { where(default_printer: true) }

  def self.for_type(type)
    type = printer_type_for(type)

    where(printer_type: type)
  end

  def self.printer_type_for(type)
    {
      'Plate' => %w(TubeRack Plate),
      'Tube' => %w(Tube SampleTube)
    }.select { |_k, v| v.include?(type) }.first[0]
  end
end
