require 'rails_helper'
require 'spec_helper'
shared_examples_for 'background task' do
  it_behaves_like 'queueable job'

  context '#Background task' do
    let(:step) { build_instance }

    context 'when a background task is saved' do
      it 'does not execute actions immediately' do
        allow(step).to receive(:execute_actions)
        step.save
        expect(step).not_to have_received(:execute_actions)
      end
    end

    context 'when execute_actions is called' do
      context 'when the process in the background is still doing changes' do
        before do
          step.update_columns(state: 'cancelling')
          allow(step).to receive(:process)
        end
        it 'does not change the state' do
          step.execute_actions
          expect(step.state).to eq('cancelling')
        end
        it 'does not run any other action' do
          step.execute_actions
          expect(step).not_to receive(:process)
        end
      end
      context 'when the process of the background task does not fail' do
        it 'sets the state to complete' do
          allow(step).to receive(:process).and_return(true)
          step.execute_actions
          expect(step.state).to eq('complete')
          expect(step.output).to eq(nil)
        end
      end
      context 'when the process of the background task fails' do
        it 'sets the state to error' do
          allow(step).to receive(:process).and_raise(StandardError, 'boom!')
          expect { step.execute_actions }.not_to raise_error
          expect(step.state).to eq('error')
          expect(step.output).to include('boom!')
        end
      end

      context 'when re-running a background task previously failed' do
        before { step.update(state: 'error', output: 'previous failure!!') }
        context 'when the step is completed correctly' do
          before do
            allow(step).to receive(:process)
            step.execute_actions
            step.reload
          end
          it 'sets the right state to the step' do
            expect(step.state).to eq('complete')
          end
          it 'resets the output for the step' do
            expect(step.output).to eq(nil)
          end
        end
        context 'when the step fails again' do
          before do
            allow(step).to receive(:process).and_raise(StandardError, 'boom!')
            expect { step.execute_actions }.not_to raise_error
            step.reload
          end
          it 'sets the right state to the step' do
            expect(step.state).to eq('error')
          end
          it 'sets the right output for to the step' do
            expect(step.output).to include('boom!')
          end
        end
      end
    end
  end
end
