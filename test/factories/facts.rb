FactoryBot.define do
  factory :fact, class: 'Fact' do
    factory :contained_well_fact do
      predicate { 'contains' }
      association(:object, factory: :well_with_samples)
    end
  end
end
