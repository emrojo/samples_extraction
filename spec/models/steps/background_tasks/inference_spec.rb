require 'rails_helper'

RSpec.describe Steps::BackgroundTasks::Inference do
  context '#run' do
    let(:activity) { create(:activity, state: 'running') }
    let(:execution) { double('step_execution') }
    let(:inference) { create :inference, activity: activity }

    before { allow(InferenceEngines::Cwm::StepExecution).to receive(:new).and_return(execution) }
    context 'when there is an error' do
      before { allow(execution).to receive(:run).and_raise(StandardError) }
      it 'changes the status to error' do
        expect { inference.run! }.to change { inference.failed? }.from(false).to(true)
      end
      it 'adds an output value explaining the error' do
        expect { inference.run! }.to change { inference.output.nil? }.to(false)
      end
    end
    context 'when there is no error' do
      before { allow(execution).to receive(:run) }

      it 'changes the status to complete' do
        inference.run!
        expect(inference.state).to eq('complete')
      end

      it 'executes the rest of next steps' do
        inferences = create_list :inference, 5, activity: activity
        inferences
          .reverse
          .reduce(nil) do |memo, step|
            id = (memo && memo.id) || nil
            step.update(next_step_id: id)

            # Step is modified by the accumulator. This is actually shown as a
            # 'good' pattern on the Lint/UnmodifiedReduceAccumulator documentation
            # so surprised its complaining here.
            step # rubocop:disable Lint/UnmodifiedReduceAccumulator
          end
        inferences.first.run!
        inferences.each(&:reload)
        inferences.each { |i| expect(i.state).to eq('complete') }
      end
    end
  end
end
