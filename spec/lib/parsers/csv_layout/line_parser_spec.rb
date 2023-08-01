require 'rails_helper'
require 'parsers/csv_layout/line_parser'
require 'parsers/csv_layout/barcode_parser'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'

RSpec.describe Parsers::CsvLayout::LineParser do
  let(:main_parser) do
    instance_double(
      Parsers::CsvLayout::CsvParser,
      components: {
        location_validator: Parsers::CsvLayout::Validators::LocationValidator,
        barcode_validator: Parsers::CsvLayout::Validators::AnyBarcodeValidator,
        barcode_parser: Parsers::CsvLayout::BarcodeParser,
        location_parser: Parsers::CsvLayout::LocationParser
      }
    )
  end
  let(:input_reader) do
    reader = double('reader')
    allow(reader).to receive(:lines).and_return(@input)
    reader
  end
  let(:parser) { Parsers::CsvLayout::LineParser.new(input_reader, main_parser) }

  before do
    @asset1 = create :asset, barcode: 'F1234'
    @asset2 = create :asset, barcode: 'F5678'
    allow(main_parser).to receive(:find_or_import_asset_with_barcode) do |barcode|
      Asset.find_by(barcode: barcode)
    end
  end

  describe '#initialize' do
    it 'can be initialized' do
      @input = [['A1', @asset1.barcode]]
      expect { parser }.not_to raise_error
    end
  end

  describe '#barcodes' do
    it 'returns a list of barcodes' do
      @input = [%w[A1 F1234], %w[A2 F5678]]
      expect(parser.barcodes).to eq %w[F1234 F5678]
    end
  end

  describe '#parsed_data' do
    it 'returns the number of lines at input' do
      @input = [%w[A1 F1234], %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data.length).to eq(@input.length)
    end
    it 'returns the parsed input' do
      @input = [%w[A1 F1234], %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data).to eq([{ location: 'A01', asset: @asset1 }, { location: 'A02', asset: @asset2 }])
    end
    it 'filters empty lines' do
      @input = [%w[A1 F1234], [], %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data).to eq([{ location: 'A01', asset: @asset1 }, { location: 'A02', asset: @asset2 }])
    end
    it 'filters nil lines' do
      @input = [%w[A1 F1234], nil, %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data).to eq([{ location: 'A01', asset: @asset1 }, { location: 'A02', asset: @asset2 }])
    end
    it 'filters nil empty lines' do
      @input = [%w[A1 F1234], [nil, nil], %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data).to eq([{ location: 'A01', asset: @asset1 }, { location: 'A02', asset: @asset2 }])
    end
    it 'filters no read barcodes' do
      @input = [%w[A1 F1234], ['B01', 'No read'], %w[A2 F5678]]
      expect(parser).to be_valid
      expect(parser.parsed_data).to eq([{ location: 'A01', asset: @asset1 }, { location: 'A02', asset: @asset2 }])
    end
  end
  context 'when the a location is not valid' do
    before { @input = [%w[A111 F1234], ['B01', 'No read'], %w[A2 F5678]] }
    it 'is invalid' do
      parser.valid?
      expect(parser).to be_invalid
    end
    it 'generates an error message' do
      expect(parser.errors.messages[:base].length == 1)
    end
  end
end
