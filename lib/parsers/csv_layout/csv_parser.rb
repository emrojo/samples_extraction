require 'parsers/csv_layout/line_parser'
require 'parsers/csv_layout/line_reader'
require 'parsers/csv_layout/barcode_parser'
require 'parsers/csv_layout/location_parser'
require 'parsers/csv_layout/validators/fluidx_barcode_validator'
require 'parsers/csv_layout/validators/location_validator'

module Parsers
  module CsvLayout
    class CsvParser # rubocop:todo Style/Documentation
      include ActiveModel::Validations

      validate :validate_parsed_data
      validate :validate_location_duplication
      validate :validate_tube_duplication

      attr_reader :data, :parsed, :parsed_changes, :components, :line_parser

      DEFAULT_COMPONENTS = {
        barcode_parser: Parsers::CsvLayout::BarcodeParser,
        location_parser: Parsers::CsvLayout::LocationParser,
        location_validator: Parsers::CsvLayout::Validators::LocationValidator,
        barcode_validator: Parsers::CsvLayout::Validators::FluidxBarcodeValidator,
        line_parser: Parsers::CsvLayout::LineParser,
        line_reader: Parsers::CsvLayout::LineReader
      }

      def initialize(str, component_defs = {})
        @parsed = false
        @input = str
        @components = self.class::DEFAULT_COMPONENTS.merge(component_defs)
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

      def layout
        parse unless @parsed
        @data
      end

      def error_list
        self_error_list = errors.messages.values.flatten
        self_error_list.concat(line_parser.error_list)
      end

      def find_or_import_asset_with_barcode(barcode)
        asset_cache.fetch(barcode, nil)
      end

      protected

      def asset_cache
        @asset_cache ||=
          Asset
            .find_or_import_assets_with_barcodes(
              @line_parser.barcodes,
              # Include the facts, any associated objects (such as tube racks)
              # and their associated facts
              # It may make sense to tidy these up with explicit associations
              includes: {
                facts: {
                  object_asset: {
                    facts: :object_asset
                  }
                }
              }
            )
            .index_by(&:barcode)
      end

      def validate_parsed_data
        parse unless @parsed
        errors.add(:base, 'The csv contains some errors') unless @line_parser.valid?
      end

      def validate_tube_duplication
        parse unless @parsed
        if @line_parser.valid?
          duplicated(:asset).each do |asset|
            errors.add(:base, "The tube with barcode #{asset.barcode} is duplicated in the file")
          end
        end
      end

      def validate_location_duplication
        parse unless @parsed
        if @line_parser.valid?
          duplicated(:location).each do |location|
            errors.add(:base, "The location #{location} is duplicated in the file")
          end
        end
      end

      def duplicated(sym)
        layout.pluck(sym).compact.uniq! || []
      end
    end
  end
end
