# frozen_string_literal: true
FactoryGirl.define do
  factory :asset do
    after(:build) do |asset|
      if Rails.configuration.respond_to?(:testing_barcodes) && asset.barcode.nil?
        asset.update_attributes(barcode: Rails.configuration.testing_barcodes.pop)
      end
    end
  end
end
