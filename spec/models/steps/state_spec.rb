require 'rails_helper'

RSpec.describe Steps::State do
  let(:activity) { create :activity }
  let(:step_type) { create :step_type }
  let(:job) { double('a job', id: 'an id') }

  it 'creates a step in pending state' do
    step = create :step, activity: activity, step_type: step_type
    expect(step).to have_state(:pending)
  end

  context 'a step can run' do
    before { allow(step).to receive(:create_job).and_return(job) }
    let(:step) { create :step, state: Step::STATE_PENDING, activity: activity, step_type: step_type }
    it 'can transition to run' do
      expect(step).to transition_from(:pending).to(:running).on_event(:run)
      expect(step).to transition_from(:failed).to(:running).on_event(:run)
    end
  end

  context 'a step can stop' do
    before { allow(step).to receive(:create_job).and_return(job) }

    let(:step) { create :step, state: Step::STATE_RUNNING, activity: activity, step_type: step_type }
    it 'can transition to pending' do
      expect(step).to transition_from(:failed).to(:stopped).on_event(:stop)
      expect(step).to transition_from(:running).to(:stopped).on_event(:stop)
      expect(step).to transition_from(:remaking).to(:cancelled).on_event(:stop)
    end
    it 'can transition to complete' do
      expect(step).to transition_from(:cancelling).to(:complete).on_event(:stop)
    end
  end

  context 'a step can be cancelled' do
    let(:step) { create :step, state: Step::STATE_COMPLETE, activity: activity, step_type: step_type }
    before { allow(step).to receive(:create_job).and_return(job) }

    it 'can transition to cancelling' do
      allow(step).to receive(:cancel_me_and_any_newer_completed_steps).and_return(nil)
      expect(step).to transition_from(:complete).to(:cancelling).on_event(:cancel)
    end
  end

  context 'a step can be remade' do
    let(:step) { create :step, state: Step::STATE_CANCELLED, activity: activity, step_type: step_type }
    before { allow(step).to receive(:create_job).and_return(job) }

    it 'can transition to remaking' do
      allow(step).to receive(:remake_me_and_any_older_cancelled_steps).and_return(nil)
      expect(step).to transition_from(:cancelled).to(:remaking).on_event(:remake)
    end
  end

  context 'a step can fail' do
    let(:step) { create :step, state: Step::STATE_RUNNING, activity: activity, step_type: step_type }
    before { allow(step).to receive(:create_job).and_return(job) }

    it 'can transition to failed' do
      expect(step).to transition_from(:running).to(:failed).on_event(:fail)
    end
  end

  context 'a step can be continued' do
    let(:step) { create :step, state: 'failed', activity: activity, step_type: step_type }
    before { allow(step).to receive(:create_job).and_return(job) }

    it 'can transition to running' do
      expect(step).to transition_from(:failed).to(:running).on_event(:continue)
    end
  end

  context 'a step that can be deprecated' do
    let(:step) { create :step, state: Step::STATE_PENDING, activity: activity, step_type: step_type }
    before { allow(step).to receive(:create_job).and_return(job) }

    it 'can transition to ignored' do
      expect(step).to transition_from(:cancelled).to(:ignored).on_event(:deprecate)
      expect(step).to transition_from(:failed).to(:ignored).on_event(:deprecate)
      expect(step).to transition_from(:pending).to(:ignored).on_event(:deprecate)
    end
  end

  context 'when changing state to complete' do
    let(:step) { create :step, state: Step::STATE_RUNNING, activity: activity, step_type: step_type }
    it 'sets the timestamp for finished_at' do
      step.complete!
      expect(step.finished_at.nil?).to eq(false)
    end
  end
  context 'when changing state to running' do
    let(:step) { create :step, state: Step::STATE_PENDING, activity: activity, step_type: step_type }
    it 'sets the timestamp for started_at' do
      step.run!
      expect(step.started_at.nil?).to eq(false)
    end
  end
end
