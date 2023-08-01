# frozen_string_literal: true

module Parsers
  module CsvLayout
    module Validators
      # Validates a location is presentandin the expected format (eg. H12)
      class LocationValidator < ActiveModel::Validator
        def validate(record)
          record.errors.add(:location, 'Invalid location') unless valid_location?(record)
        end

        protected

        def valid_location?(record)
          record.location.present? && record.location.match?(TokenUtil::LOCATION_REGEXP)
        end
      end
    end
  end
end
