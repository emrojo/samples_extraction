module Parsers
  module CsvMetadata
    class LineParser # rubocop:todo Style/Documentation
      include ActiveModel::Validations
      attr_reader :parsed_content, :headers_parser

      validate :validate_parsed_content

      def initialize(input_reader, parser)
        @parser = parser
        @parsed_content = []
        @parsed = false
        @input_reader = input_reader
      end

      def parsed_data
        @parsed_content.map { |entry| entry[:data_parser].data } if valid?
      end

      def error_list_for_parser(parser, numline)
        parser.errors.messages.values.map { |msg| "At line #{numline}: #{msg[0]}" }
      end

      def error_list
        parsed_content.map { |entry| error_list_for_parser(entry[:data_parser], entry[:num_line]) }
      end

      protected

      def validate_parsed_content
        parse unless @parsed
        @parsed_content.each do |entry|
          errors.add(:base, "There is an error at line #{entry[:num_line]}") unless entry[:data_parser].valid?
        end
      end

      def parse
        num_line = 1
        @input_reader
          .lines
          .reduce(@parsed_content) do |memo, line|
            if num_line == 1
              @parser.headers_parser = @parser.components[:headers_parser].new(line, @parser)
            else
              unless empty_line?(line)
                data_parser = @parser.components[:data_parser].new(line, @parser)
                memo.push(num_line: num_line, data_parser: data_parser)
              end
            end
            num_line = num_line + 1
            memo
          end
        @parsed = true

        parsed_data
      end

      def empty_line?(line)
        (line.nil? || (line.length == 0) || line.all?(&:nil?))
      end
    end
  end
end
