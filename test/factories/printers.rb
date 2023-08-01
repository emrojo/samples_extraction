FactoryBot.define do
  factory :printer do
    sequence(:name) { |i| "#{printer_type} Printer #{i}".strip }

    factory :tube_printer do
      printer_type { 'Tube' }
    end

    factory :plate_printer do
      printer_type { 'Plate' }
    end
  end
end
