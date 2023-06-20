require 'rails_helper'
require 'parsers/csv_layout/validators/location_validator'

RSpec.describe Parsers::CsvLayout::Validators::LocationValidator do
  let(:klass) do
    Class.new do
      attr_accessor :location

      include ActiveModel::Validations
      validates_with Parsers::CsvLayout::Validators::LocationValidator
    end
  end
  let(:instance) { klass.new }
  it 'validates a valid location' do
    instance.location = 'A01'
    expect(instance).to be_valid
  end
  it 'does not validate an invalid location' do
    instance.location = 'A111'
    expect(instance).to be_invalid
  end
  it 'does validate an unpadded location' do
    instance.location = 'A1'
    expect(instance).to be_valid
  end
  it 'does not validate an empty location' do
    instance.location = ''
    expect(instance).to be_invalid
  end
end
