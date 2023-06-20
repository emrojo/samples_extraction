module Parsers
  module CsvMetadata
    class HeadersParser # rubocop:todo Style/Documentation
      attr_reader :headers

      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with @parser.components[:headers_validator]
      end

      def initialize(line, parser)
        @parser = parser
        _parse(line)

        valid?
      end

      def _parse(line)
        @headers = line.map { |header| header.strip }
      end
    end
  end
end
