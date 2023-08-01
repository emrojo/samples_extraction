module Parsers
  module CsvLayout
    class LineParser # rubocop:todo Style/Documentation
      include ActiveModel::Validations

      validate :validate_parsed_content

      def initialize(input_reader, parser)
        @parser = parser
        @input_reader = input_reader
      end

      def parsed_data
        if valid?
          parsed_content.filter_map do |entry|
            next if entry[:barcode_parser].no_read_barcode?

            { location: entry[:location_parser].location, asset: entry[:barcode_parser].asset }
          end
        end
      end

      def error_list_for_parser(parser, line_number)
        parser.errors.messages.values.map { |msg| "At line #{line_number}: #{msg[0]}" }
      end

      def error_list
        parsed_content.map do |entry|
          [
            error_list_for_parser(entry[:location_parser], entry[:num_line]),
            error_list_for_parser(entry[:barcode_parser], entry[:num_line])
          ]
        end.flatten
      end

      def parsed_content
        @parsed_content ||= parse
      end

      def barcodes
        parsed_content.filter_map { |line| line[:barcode_parser].barcode }.uniq
      end

      protected

      def validate_parsed_content
        parsed_content.each do |entry|
          next if entry[:location_parser].valid? && entry[:barcode_parser].valid?

          errors.add(:base, "There is an error at line #{entry[:num_line]}")
        end
      end

      def parse
        @input_reader.lines.filter_map.with_index do |line, num_line|
          next if empty_line?(line)

          barcode_parser = @parser.components[:barcode_parser].new(line, @parser)
          next if barcode_parser.no_read_barcode?

          location_parser = @parser.components[:location_parser].new(line, @parser)
          { location_parser: location_parser, barcode_parser: barcode_parser, num_line: num_line }
        end
      end

      def empty_line?(line)
        (line.nil? || (line.length == 0) || line.all?(&:nil?))
      end
    end
  end
end
