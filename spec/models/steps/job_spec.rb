require 'rails_helper'

RSpec.describe Steps::Job do
  let(:activity) { create :activity }
  let(:step) { create(:step, activity: activity) }

  context '#execute_actions' do
    let(:job_double) { double('job') }
    before do
      allow(job_double).to receive(:id).and_return('1')
      allow(step).to receive(:perform_job).and_return(job_double)
    end
    context 'if the step is not already processing' do
      it 'adds the step to the queue to run in future' do
        expect { step.run }.to change { step.job_id }
      end
      it 'changes the state to running' do
        expect { step.run }.to change { step.running? }.from(false).to(true)
      end
      it 'calls #perform_job asynchronously' do
        step.run
        expect(step).to have_received(:perform_job)
      end
    end
    context 'if the step is already processing' do
      before { step.update_columns(state: Step::STATE_RUNNING) }
      it 'does nothing' do
        expect { step.run }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  context '#perform_job' do
    context 'if the step state is still running' do
      before { step.update_columns(state: Step::STATE_RUNNING) }
      context 'when calling #process' do
        context 'when there is no error' do
          before { allow(step).to receive(:process) }
          it 'changes the state to complete' do
            expect { step.perform_job }.to change { step.complete? }.from(false).to(true)
          end
        end
        context 'when there is an error' do
          before { allow(step).to receive(:process).and_raise('boom!!') }
          it 'does not propagate the exception' do
            expect { step.perform_job }.not_to raise_error
          end
          it 'changes the state to error' do
            expect { step.perform_job }.to change { step.failed? }.from(false).to(true)
          end
        end
      end
    end
    context 'if the step is already processing something else' do
      before { step.update_columns(state: 'stopping') }
      it 'does nothing' do # rubocop:todo Lint/EmptyBlock
      end
    end
  end
end
