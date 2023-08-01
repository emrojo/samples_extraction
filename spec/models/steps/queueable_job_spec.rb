require 'rails_helper'

RSpec.describe 'Steps::QueuableJob' do
  let(:activity) { create :activity }
  let(:step_type) { create :step_type }
  let(:asset_group) { create :asset_group }
  let(:user) { create :user, username: 'test' }

  def build_instance_with_activity
    step = create(:step, { activity: activity, step_type: step_type, asset_group: asset_group, user: user })
  end

  context 'when a background step is completed' do
    let(:step) { build_instance_with_activity }
    context 'when there was an error in its execution' do
      before do
        allow(step).to receive(:process) do
          raise StandardError
          # step.update(state: 'error')
        end
      end
      context 'when it has a next step configured' do
        let(:another_step) { build_instance_with_activity }
        it 'does not execute the next step' do
          step.update(next_step: another_step)
          allow(another_step).to receive(:run!)
          expect { step.run! }.not_to raise_error
          expect(another_step).not_to have_received(:run!)
        end
      end

      context 'when it has several steps configured' do
        let(:my_steps) { Array.new(5) { build_instance_with_activity } }
        it 'does not execute any of the steps' do
          my_steps
            .reverse
            .reduce(nil) do |next_step, step|
              step.update(next_step: next_step)
              allow(step).to receive(:process)

              # Step is modified by the accumulator. This is actually shown as a
              # 'good' pattern on the Lint/UnmodifiedReduceAccumulator documentation
              # so surprised its complaining here.
              step # rubocop:disable Lint/UnmodifiedReduceAccumulator
            end
          step.update(next_step: my_steps.first)
          expect { step.run! }.not_to raise_error
          expect(my_steps.last).not_to have_received(:process)
        end
      end
    end
    context 'when the step is still in progress and has a next step' do
      let(:another_step) { build_instance_with_activity }
      before do
        allow(another_step).to receive(:run!)
        allow(step).to receive(:run!) do
          step.update(state: 'in_progress')
        end
        step.update(next_step: another_step)
      end
      it 'does not execute the next step' do
        step.run!
        expect(another_step).not_to have_received(:run!)
      end
    end
    context 'when the step is still running and has a next step' do
      let(:another_step) { build_instance_with_activity }
      before do
        allow(another_step).to receive(:run!)
        allow(step).to receive(:run!) do
          step.update(state: 'running')
        end
        step.update(next_step: another_step)
      end
      it 'does not execute the next step' do
        step.run!
        expect(another_step).not_to have_received(:run!)
      end
    end

    context 'when there was no error in its execution' do
      context 'when it has a next step configured' do
        let(:another_step) { build_instance_with_activity }

        context 'when the next step is compatible with the assets it has to process' do
          it 'executes the next step' do
            allow(another_step).to receive(:run!)
            allow(step).to receive(:process)
            step.update(next_step: another_step)
            step.run!
            another_step.reload
            expect(another_step.state.to_sym).to eq(Step::STATE_COMPLETE)
          end
        end
        context 'when the next step is not compatible' do
          before do
            st = create :step_type
            st.update(n3_definition: '{ ?p :a :nothing . } => { } .')

            another_step.update(step_type: st)
          end
          it 'ignores that step' do
            allow(another_step).to receive(:run!)
            allow(step).to receive(:process)
            step.update(next_step: another_step)
            step.run!
            another_step.reload
            expect(another_step.state.to_sym).to eq(Step::STATE_IGNORED)
          end
        end
      end
      context 'when it has several steps configured' do
        let(:my_steps) { Array.new(5) { build_instance_with_activity } }

        context 'when all the steps are correct' do
          it 'executes all steps until the last one' do
            my_steps
              .reverse
              .reduce(nil) do |next_step, step|
                step.update(next_step: next_step)
                allow(step).to receive(:run!) do
                  step.update(state: 'complete')
                end

                # Step is modified by the accumulator. This is actually shown as a
                # 'good' pattern on the Lint/UnmodifiedReduceAccumulator documentation
                # so surprised its complaining here.
                step # rubocop:disable Lint/UnmodifiedReduceAccumulator
              end
            my_steps.first.run!
            expect(my_steps.last).to have_received(:run!)
          end
        end

        context 'when one of the steps has a failure' do
          def mock_step_completion(s, state)
            allow(s).to receive(:run!) do
              s.update(state: state)
            end
          end
          before do
            my_steps
              .reverse
              .reduce(nil) do |next_step, step|
                step.update(next_step: next_step)

                # Step is modified by the accumulator. This is actually shown as a
                # 'good' pattern on the Lint/UnmodifiedReduceAccumulator documentation
                # so surprised its complaining here.
                step # rubocop:disable Lint/UnmodifiedReduceAccumulator
              end
            mock_step_completion(my_steps[0], 'complete')
            mock_step_completion(my_steps[1], 'complete')
            mock_step_completion(my_steps[2], 'error')
            mock_step_completion(my_steps[3], 'complete')
            mock_step_completion(my_steps[4], 'complete')
          end

          it 'executes all the steps until the one that fails' do
            my_steps.first.run!
            expect(my_steps[1]).to have_received(:run!)
            expect(my_steps[2]).to have_received(:run!)
          end
          it 'does not execute steps after the one that fails' do
            my_steps.first.run!
            expect(my_steps[3]).not_to have_received(:run!)
            expect(my_steps[4]).not_to have_received(:run!)
          end
        end
      end
      context 'when it does not have a next step' do
        before do
          allow(step).to receive(:run!) do
            step.update(state: 'complete')
          end
        end
        it 'does not raise an error' do
          step.update(next_step: nil)
          expect { step.run! }.not_to raise_error
        end
      end
    end
  end
end
