require 'rails_helper'
require 'parsers/csv_layout/line_reader'

RSpec.describe Parsers::CsvLayout::LineReader do
  let(:parserClass) { Parsers::CsvLayout::LineReader }
  let(:result) { [%w[A01 1234], %w[B01 4567], %w[C01 8901]] }
  it 'recognises line feed for new line' do
    expect(parserClass.new("A01,1234\nB01,4567\nC01,8901").lines).to eq(result)
    expect(parserClass.new("A01,1234\nB01,4567\nC01,8901\n").lines).to eq(result)
  end
  it 'recognises carriage return as new line' do
    expect(parserClass.new("A01,1234\rB01,4567\rC01,8901").lines).to eq(result)
    expect(parserClass.new("A01,1234\rB01,4567\rC01,8901\r").lines).to eq(result)
  end
  it 'recognises carriage return with line feed as new line' do
    expect(parserClass.new("A01,1234\r\nB01,4567\r\nC01,8901").lines).to eq(result)
    expect(parserClass.new("A01,1234\r\nB01,4567\r\nC01,8901\r\n").lines).to eq(result)
  end
  it 'ignores the bom header if set' do
    content = "#{Parsers::CsvLayout::LineReader::BOM_HEADER}A01,1234\nB01,4567\nC01,8901"
    expect(parserClass.new(content).lines).to eq(result)
  end
end
