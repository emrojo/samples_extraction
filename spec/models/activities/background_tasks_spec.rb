require 'rails_helper'

RSpec.describe 'BackgroundTasks' do
  # Mock step for testing. Should probably be anonymous class
  class DummyBackgroundStep
    def self.create!(params)
      @instance = FactoryBot.create(:step, params)
    end

    def self.update!(params)
      @instance.update!(params)
    end
  end

  let(:activity) { create :activity }
  let(:step_type) { create :step_type }
  let(:asset_group) { create :asset_group }
  let(:step) { create :step, step_type: step_type }

  context '#create_background_steps' do
    let(:list_of_tasks) { Array.new(5) { DummyBackgroundStep } }
    it 'creates the list of steps' do
      activity.create_background_steps(list_of_tasks, {})
      expect(Step.all.count).to eq(5)
    end
    it 'connects each step with the next one' do
      activity.create_background_steps(list_of_tasks, {})
      steps = Step.all
      steps.each_with_index { |s, idx| expect(s.next_step).to eq(steps[idx + 1]) if (idx + 1) < steps.count }
    end
  end

  context '#create_connected_tasks' do
    let(:list_of_tasks) { Array.new(5) { DummyBackgroundStep } }

    let(:other_step) { create :step, step_type: step_type }
    context 'when it does not have any background task defined' do
      it 'does not raise an error' do
        allow(activity).to receive(:background_tasks).and_return([])
        expect { activity.create_connected_tasks(step, asset_group) }.not_to raise_exception
      end
    end
    context 'when it has background tasks' do
      it 'creates a list of connected tasks' do
        allow(activity).to receive(:background_tasks).and_return([Step])
        expect(activity.create_connected_tasks(step, asset_group).length).to eq(2)
      end
    end
  end

  context '#background_tasks' do
    it 'returns the list of inference tasks sorted by priority' do
      step_types = 5.times.each_with_index.map { |_i| create :step_type }
      reasoning_step_types = 4.times.each_with_index.map { |i| create :step_type, { for_reasoning: true, priority: i } }
      activity.activity_type.update(step_types: step_types.concat(reasoning_step_types))

      expect(activity.background_tasks.count).to eq(reasoning_step_types.count)
      expect(activity.background_tasks.map(&:step_type)).to eq(reasoning_step_types.reverse)
    end
  end
end
