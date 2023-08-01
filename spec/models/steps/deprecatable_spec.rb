require 'rails_helper'

RSpec.describe 'Steps::Deprecatable' do
  let(:activity) { create(:activity) }
  let(:asset_group) { create(:asset_group) }
  let(:step_type) { create(:step_type) }
  context '#execute_actions' do
    let(:state) { Step::STATE_CANCELLED }
    it 'deprecates all cancelled steps created before me on step execution' do
      steps = create_list(:step, 10, state: state, activity: activity)
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type)

      expect(steps.all?(&:cancelled?)).to eq(true)
      expect(activity.steps.count).to eq(11)
      step.run!
      steps.each(&:reload)
      expect(steps.all?(&:ignored?)).to eq(true)
      expect(activity.steps.count).to eq(1)
    end

    it 'deprecates all stopped steps created before me on step execution' do
      steps = create_list(:step, 10, state: Step::STATE_STOPPED, activity: activity)
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type)

      expect(activity.steps.count).to eq(11)
      step.run!
      steps.each(&:reload)
      expect(steps.all?(&:ignored?)).to eq(true)
      expect(activity.steps.count).to eq(1)
    end

    it 'does not deprecate anything if is completed' do
      steps = create_list(:step, 10, state: Step::STATE_COMPLETE, activity: activity)
      step =
        create(:step, activity: activity, state: Step::STATE_PENDING, asset_group: asset_group, step_type: step_type)

      expect(activity.steps.count).to eq(11)
      step.run!
      steps.each(&:reload)
      expect(steps.any?(&:ignored?)).to eq(false)
      expect(activity.steps.count).to eq(11)
    end

    it 'does not deprecate anything created after me' do
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type)
      steps = create_list(:step, 10, state: 'cancelled', activity: activity)

      expect(activity.steps.count).to eq(11)
      step.run!
      steps.each(&:reload)
      expect(steps.any?(&:ignored?)).to eq(false)
      expect(activity.steps.count).to eq(11)
    end

    it 'does not deprecate any steps created before me that are in my chain for next_step' do
      steps =
        create_list(
          :step,
          10,
          state: Step::STATE_STOPPED,
          activity: activity,
          asset_group: asset_group,
          step_type: step_type
        )
      step = create(:step, activity: activity, asset_group: asset_group, step_type: step_type, next_step: steps.last)

      expect(activity.steps.count).to eq(11)
      step.run!
      steps.each(&:reload)
      expect(steps.count(&:ignored?)).to eq(9)
      expect(activity.steps.count).to eq(2)
    end
  end
end
