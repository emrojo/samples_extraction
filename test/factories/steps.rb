FactoryBot.define do
  factory :step

  factory :background_task, class: 'Steps::BackgroundTasks::BackgroundTask' do
    step_type { create :step_type }
  end
end
