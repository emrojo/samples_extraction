module Parsers
  module CsvLayout
    class LocationParser
      include ActiveModel::Validations

      validate :validations

      def validations
        validates_with @parser.components[:location_validator]
      end

      attr_reader :location

      def initialize(line, parser)
        @parser = parser
        parse(line)
      end

      private

      def parse(line)
        begin
          @location = TokenUtil.pad_location(line[0].strip)
        rescue StandardError => e
          @location = nil
        end
      end

    end
  end
end
