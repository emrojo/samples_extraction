require 'parsers/csv_layout/barcode_parser'

module Parsers
  module CsvLayout
    # Used to automatically register an empty tube with the given barcode if
    # the barcode doesn't already exist in either Sequencescape or
    # Samples Extraction.
    class BarcodeCreatableParser < BarcodeParser
      def updater
        @parser.parsed_changes
      end

      def asset
        @asset ||= @parser.find_or_import_asset_with_barcode(barcode) || generate_asset
      end

      def generate_asset
        Asset
          .new(barcode: barcode)
          .tap do |tube|
            updater.create_assets([tube])
            updater.add(tube, 'barcode', barcode)
            updater.add(tube, 'a', 'Tube')
            updater.add(tube, 'barcodeType', 'Code2D') if TokenUtil.is_valid_fluidx_barcode?(barcode)
            updater.add(tube, 'is', 'Empty')
          end
      end
    end
  end
end
