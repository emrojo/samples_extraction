require 'rails_helper'

require 'parsers/csv_layout/validators/fluidx_barcode_validator'

RSpec.describe Parsers::CsvLayout::Validators::FluidxBarcodeValidator do
  let(:klass) do
    Class.new do
      attr_accessor :barcode

      include ActiveModel::Validations
      validates_with Parsers::CsvLayout::Validators::FluidxBarcodeValidator
    end
  end
  let(:instance) { klass.new }
  it 'validates a fluidx barcode' do
    instance.barcode = 'F1234'
    expect(instance).to be_valid
  end
  it 'does not validate a normal barcode' do
    instance.barcode = '1234'
    expect(instance).to be_invalid
  end
  it 'does not validate an empty barcode' do
    instance.barcode = ''
    expect(instance).to be_invalid
  end
end
