# frozen_string_literal: true
FactoryGirl.define do
  factory :user_with_barcode, class: User do
    barcode  { FactoryGirl.generate :barcode }
  end

  factory :user, class: User do
    barcode  { FactoryGirl.generate :barcode }
  end
end
