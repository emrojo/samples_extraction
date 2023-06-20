FactoryBot.define do
  factory :instrument do
    barcode { FactoryBot.generate :barcode }
  end
end
