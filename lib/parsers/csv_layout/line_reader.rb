require 'csv'
module Parsers
  module CsvLayout
    class LineReader # rubocop:todo Style/Documentation
      BOM_HEADER = "\xEF\xBB\xBF"

      def initialize(input)
        @input = input
      end

      def lines
        csv_convert(clean_input(@input))
      end

      protected

      def clean_input(str)
        clean_bom(str.kind_of?(String) ? str.gsub("\r\n", "\n") : str)
      end

      def clean_bom(str)
        str.force_encoding('UTF-8').sub(BOM_HEADER, '')
      end

      def csv_convert(str)
        CSV.new(str).to_a
      end
    end
  end
end
