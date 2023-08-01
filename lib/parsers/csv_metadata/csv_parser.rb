require 'parsers/csv_metadata/headers_parser'
require 'parsers/csv_metadata/line_parser'
require 'parsers/csv_metadata/data_parser'
require 'parsers/csv_layout/line_reader'
require 'parsers/csv_metadata/validators/headers_validator'

module Parsers
  module CsvMetadata
    class CsvParser # rubocop:todo Style/Documentation
      include ActiveModel::Validations

      validate :validate_parsed_data

      attr_accessor :headers_parser
      attr_reader :data, :parsed, :parsed_changes, :components, :line_parser

      DEFAULT_COMPONENTS = {
        headers_parser: Parsers::CsvMetadata::HeadersParser,
        data_parser: Parsers::CsvMetadata::DataParser,
        line_parser: Parsers::CsvMetadata::LineParser,
        line_reader: Parsers::CsvLayout::LineReader,
        headers_validator: Parsers::CsvMetadata::Validators::HeadersValidator
      }

      def initialize(str, component_defs = {})
        @parsed = false
        @input = str
        @components = self.class::DEFAULT_COMPONENTS.merge(component_defs)
        valid?
      end

      def parsed?
        @parsed
      end

      def parse
        unless @parsed
          @parsed = false
          @parsed_changes = FactChanges.new
          @line_reader = components[:line_reader].new(@input)
          @line_parser = components[:line_parser].new(@line_reader, self)
          @data ||= @line_parser.parsed_data
          @parsed = true
        end
        @parsed
      end

      def metadata
        parse unless @parsed
        @data
      end

      def create_tubes?
        false
      end

      def error_list
        line_parser.error_list
      end

      protected

      def validate_parsed_data
        parse unless @parsed
        errors.add(:base, 'The csv contains some errors') unless @line_parser.valid?
      end
    end
  end
end
