# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Printer, type: :model do
  context 'self.printer_type_for' do
    it 'returns the right printer type' do
      expect(Printer.printer_type_for('Tube')).to eq('Tube')
      expect(Printer.printer_type_for('SampleTube')).to eq('Tube')
      expect(Printer.printer_type_for('Plate')).to eq('Plate')
      expect(Printer.printer_type_for('TubeRack')).to eq('Plate')
    end
  end
end
