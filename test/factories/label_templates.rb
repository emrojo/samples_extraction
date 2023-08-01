FactoryBot.define do
  factory :label_template do
    external_id

    factory :tube_label_template do
      name { 'se_code128_1dtube' }
      template_type { 'Tube' }
    end

    factory :plate_label_template do
      name { 'se_code128_96plate' }
      template_type { 'Plate' }
    end
  end

  sequence(:external_id) { |i| i }
end
