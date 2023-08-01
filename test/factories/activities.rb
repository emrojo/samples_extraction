FactoryBot.define do
  factory :activity do
    activity_type { create :activity_type }
    asset_group { create :asset_group }

    factory :finished_activity do
      state { 'finish' }
      completed_at { DateTime.current }
    end
  end
end
