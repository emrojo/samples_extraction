FactoryBot.define do
  factory :kit do
    barcode { FactoryBot.generate :barcode }
  end
end
