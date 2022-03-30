require 'rails_helper'
RSpec.describe 'Steps::Stoppable' do
  let(:activity) { create(:activity) }
  let(:asset_group) { create(:asset_group) }
  let(:step_type) { create(:step_type) }

  let(:previous_steps) {
    create_list(:step, 2, state: Step::STATE_RUNNING, activity: activity, asset_group: asset_group, step_type: step_type)
  }
  let(:next_steps) {
    create_list(:step, 2, state: Step::STATE_RUNNING, activity: activity, asset_group: asset_group, step_type: step_type)
  }

  let(:step) { create(:step, state: previous_state, activity: activity, asset_group: asset_group, step_type: step_type) }

  context 'when a step is stopped' do
    let(:do_action) {
      steps = [previous_steps, step, next_steps].flatten
      step.stop!
      steps.each(&:reload)
    }

    context 'but the step was already completed before' do
      let(:previous_state) { Step::STATE_COMPLETE }
      before do
        do_action
      end
      it 'stops any other steps after this step' do
        expect(next_steps.all?(&:stopped?)).to eq(true)
      end
      it 'does not stop any steps before this step' do
        expect(previous_steps.all?(&:complete?)).to eq(false)
      end
      it 'rolls back the state of the step to complete because we cannot stop a step that has already been applied' do
        expect(step.complete?).to eq(true)
      end
    end
    context 'when the step was not completed before' do
      let(:previous_state) { Step::STATE_RUNNING }
      before do
        asset = create :asset
        step.operations << create(:operation, action_type: 'create_assets', object: asset.uuid, :cancelled? => false)
        do_action
      end

      it 'stops any other steps after this step' do
        expect(next_steps.all?(&:stopped?)).to eq(true)
      end
      it 'does not stop any steps before this step' do
        expect(previous_steps.all?(&:complete?)).to eq(false)
      end
      it 'performs cancelling of the operations for this step' do
        expect(step.operations.all?(&:cancelled?)).to eq(true)
      end
      it 'stops this step' do
        expect(step.stopped?).to eq(true)
      end
    end
  end
  context 'when a step is continued' do
    let(:do_action) {
      steps = [previous_steps, step, next_steps].flatten
      step.continue!
      steps.each(&:reload)
    }

    let(:next_steps_stopped) {
      create_list(:step, 2, state: Step::STATE_STOPPED, activity: activity, asset_group: asset_group, step_type: step_type)
    }
    let(:next_steps_not_stopped) {
      create_list(:step, 2, state: Step::STATE_FAILED, activity: activity, asset_group: asset_group, step_type: step_type)
    }
    let(:next_steps) { [next_steps_stopped, next_steps_not_stopped].flatten }

    context 'when the step was stopped before' do
      let(:previous_state) { Step::STATE_STOPPED }
      before do
        asset = create :asset
        step.operations << create(:operation, action_type: 'create_assets', object: asset.uuid, :cancelled? => false)

        do_action
      end

      it 'continues this step' do
        expect(step.complete?).to eq(true)
      end
      it 'performs remaking of the operations for this step' do
        step.operations.reload

        expect(step.operations.all?(&:cancelled?)).to eq(false)
      end
      it 'continues with any other stopped steps after this step' do
        expect(next_steps_stopped.all?(&:complete?)).to eq(true)
      end
      it 'does not continue with any not stopped steps after this step' do
        expect(next_steps_not_stopped.all?(&:complete?)).to eq(false)
      end
      it 'does not change the state of previous steps' do
        expect(previous_steps.all?(&:running?)).to eq(true)
      end
    end
    context 'when the step was not stopped before' do
      let(:previous_state) { Step::STATE_RUNNING }
      before do
        do_action
      end

      it 'does not continue any other stopped steps after this step' do
        expect(next_steps_stopped.all?(&:stopped?)).to eq(true)
      end
      it 'does not continue with any not stopped steps after this step' do
        expect(next_steps_not_stopped.all?(&:complete?)).to eq(false)
      end
      it 'does not change the state of previous steps' do
        expect(previous_steps.all?(&:running?)).to eq(true)
      end
    end
  end
end
