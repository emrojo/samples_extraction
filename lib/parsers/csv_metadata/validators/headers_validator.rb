# frozen_string_literal: true

module Parsers
  module CsvMetadata
    module Validators
      # Validates that the headers aren't empty
      class HeadersValidator < ActiveModel::Validator
        def validate(record)
          record.headers.each_with_index do |header, index|
            record.errors.add(:header, "Header #{index} is empty") if header.empty?
          end
        end
      end
    end
  end
end
