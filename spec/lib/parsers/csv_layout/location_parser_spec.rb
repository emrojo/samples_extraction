require 'rails_helper'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/location_validator'

RSpec.describe Parsers::CsvLayout::LocationParser do
  let(:main_parser) do
    main = double('parser')
    allow(main).to receive(:add_error)
    allow(main).to receive(:components).and_return(
      { location_validator: Parsers::CsvLayout::Validators::LocationValidator }
    )
    main
  end
  let(:barcode) { '1234' }
  let(:location) { 'A10' }
  let(:input) { [location, barcode] }
  context '#initialize' do
    let(:parser) { Parsers::CsvLayout::LocationParser.new(input, main_parser) }
    it 'can be initialized' do
      expect { parser.location }.not_to raise_error
    end
    it 'returns the location' do
      expect(parser.location).to eq(location)
    end
    it 'chomps empty spaces before and after the location' do
      parser = Parsers::CsvLayout::LocationParser.new(['  A01  ', '   F1234  '], main_parser)
      expect(parser.location).to eq('A01')
    end
  end

  it 'can parse a line' do
    expect(Parsers::CsvLayout::LocationParser.new(%w[A01 F123456], main_parser).location).to eq('A01')
  end
  it 'can pad the location' do
    expect(Parsers::CsvLayout::LocationParser.new(%w[A1 F123456], main_parser).location).to eq('A01')
  end

  it 'validates when the location is right' do
    parser = Parsers::CsvLayout::LocationParser.new(%w[A1 F123456], main_parser)
    expect(parser).to be_valid
  end

  it 'does not validate when the location is wrong' do
    parser = Parsers::CsvLayout::LocationParser.new(%w[A111 F123456], main_parser)
    expect(parser).to be_invalid
  end
end
