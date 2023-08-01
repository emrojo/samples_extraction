# frozen_string_literal: true

module Parsers
  module CsvLayout
    module Validators
      # Validates that a barcode is present, but doesn't care if the asset
      # exists
      class AnyBarcodeValidator < ActiveModel::Validator
        def validate(record)
          record.errors.add(:barcode, 'is empty') if record.barcode.blank?
        end
      end
    end
  end
end
