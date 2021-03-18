require 'rails_helper'
require 'parsers/csv_metadata/validators/headers_validator'

RSpec.describe Parsers::CsvMetadata::Validators::HeadersValidator do
  let(:klass) {
    Class.new {
      attr_accessor :headers

      include ActiveModel::Validations
      validates_with Parsers::CsvMetadata::Validators::HeadersValidator
    }
  }
  let(:instance) { klass.new }
  it 'validates normal headers' do
    instance.headers = ["h1", "h2"]
    expect(instance).to be_valid
  end
  it 'does not validate an empty header' do
    instance.headers = ["h1", "h2", ""]
    expect(instance).to be_invalid
  end
end
