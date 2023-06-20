FactoryBot.define do
  factory :asset do
    transient do
      # NOTE: For all these fact attributes tou can set the value to an array
      # with the second argument a hash. This will let you set other fact
      # attributes. Eg: `create :asset, purpose: ['Stock', { is_remote?: true}
      # ]` Will create a purpose fact, with the value 'Stock' with is_remote?
      # set to true
      a { nil }
      location { nil }
      supplier_sample_name { nil }
      sample_uuid { nil }
      purpose { nil }
      study_name { nil }
      aliquot_type { nil }
      fact_attributes { {} }

      _fact_attributes do
        {
          'a' => a,
          'location' => location,
          'supplier_sample_name' => supplier_sample_name,
          'sample_uuid' => sample_uuid,
          'purpose' => purpose,
          'study_name' => study_name,
          'aliquotType' => aliquot_type
        }.compact.merge(fact_attributes)
      end
    end

    facts do
      _fact_attributes.map do |predicate, (object, options)|
        build(:fact, { asset: instance, predicate: predicate, object: object, **(options || {}) })
      end
    end

    factory :plate do
      transient do
        a { 'Plate' }
        well_attributes { [] }
      end

      barcode

      facts do
        _fact_attributes
          .map do |predicate, (object, options)|
            build(:fact, { predicate: predicate, object: object, **(options || {}) })
          end
          .concat(
            well_attributes.map do |attributes|
              well = build :well_with_samples, attributes
              build :fact, predicate: 'contains', object_asset: well
            end
          )
      end
    end

    factory :well_with_samples do
      transient do
        supplier_sample_name { 'Sample Name' }
        sample_uuid { SecureRandom.uuid }
        a { 'Well' }
      end

      barcode { nil }
    end
  end
end
