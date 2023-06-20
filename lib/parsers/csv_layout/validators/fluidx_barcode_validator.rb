# frozen_string_literal: true

module Parsers
  module CsvLayout
    module Validators
      # Validates that the barcode matches the Fluidx format
      class FluidxBarcodeValidator < ActiveModel::Validator
        def validate(record)
          return if valid_fluidx_barcode?(record)

          record.errors.add(:barcode, "Invalid fluidx barcode format #{record.barcode}")
        end

        protected

        def valid_fluidx_barcode?(record)
          TokenUtil.is_valid_fluidx_barcode?(record.barcode)
        end
      end
    end
  end
end
