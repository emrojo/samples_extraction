# frozen_string_literal: true
FactoryGirl.define do
  factory :kit do
    barcode { FactoryGirl.generate :barcode }
  end
end
