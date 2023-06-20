# frozen_string_literal: true

module Parsers
  module CsvLayout
    class BarcodeParser # rubocop:todo Style/Documentation
      NO_READ_BARCODE = 'no read'

      include ActiveModel::Validations

      validates :asset, presence: { message: 'Cannot find the barcode' }, if: :barcode? # rubocop:todo Rails/I18nLocaleTexts
      validate :validations

      def validations
        validates_with @parser.components[:barcode_validator]
      end

      attr_reader :barcode, :asset

      def initialize(line, parser)
        @parser = parser
        parse(line)
      end

      def no_read_barcode?
        !!barcode&.downcase&.start_with?(NO_READ_BARCODE)
      end

      def asset
        @parser.find_or_import_asset_with_barcode(barcode)
      end

      def barcode?
        barcode.present? && !no_read_barcode?
      end

      private

      def parse(line)
        @barcode = line[1]&.strip
      end
    end
  end
end
