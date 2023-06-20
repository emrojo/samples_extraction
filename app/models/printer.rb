class Printer < ApplicationRecord # rubocop:todo Style/Documentation
  CLASS_TYPE_PRINTER_ALIASES = { 'TubeRack' => 'Plate', 'SampleTube' => 'Tube' }.freeze

  scope :for_tube, -> { where(printer_type: 'Tube') }
  scope :for_plate, -> { where(printer_type: 'Plate') }
  scope :for_default, -> { where(default_printer: true) }

  def self.for_type(type)
    where(printer_type: printer_type_for(type))
  end

  def self.printer_type_for(class_type)
    CLASS_TYPE_PRINTER_ALIASES.fetch(class_type, class_type)
  end
end
