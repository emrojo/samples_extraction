FactoryBot.define do
  factory :user_with_barcode, class: User do
    barcode { FactoryBot.generate :barcode }
  end

  factory :user, class: User do
    barcode { FactoryBot.generate :barcode }
  end
end
