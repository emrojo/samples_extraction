require 'rails_helper'

describe Steps::Task do
  let(:user) { create :user, username: 'test' }
  let(:printer_config) { { 'Plate' => 'plates', 'Tube' => 'tubes', 'TubeRack' => 'plates' } }
  def build_instance
    asset_group = build :asset_group
    build :step, asset_group: asset_group, printer_config: printer_config
  end

  def create_instance(step_type, activity, group)
    create(
      :step,
      step_type: step_type,
      activity: activity,
      asset_group: group,
      user: user,
      printer_config: printer_config
    )
  end

  # it_behaves_like 'background task'

  context 'a background task with some changes defined' do
    let(:step_type) do
      create(
        :step_type,
        step_action: step_action,
        condition_groups: [cg],
        actions: [
          create(:action, action_type: 'createAsset', predicate: 'a', object: 'Tube', subject_condition_group: cg2)
        ]
      )
    end
    let(:cg) { create :condition_group, conditions: [create(:condition, predicate: 'a', object: 'Plate')] }
    let(:cg2) { create :condition_group }
    let(:group) { create :asset_group, assets: [asset] }
    let(:activity) { create :activity }
    let(:asset) { create :asset, a: 'Plate' }

    context 'when the step type does not have a step action' do
      let(:step_action) { nil }
      it 'runs the rule defined by the step type' do
        asset.reload

        step = create_instance(step_type, activity, group)
        expect { step.run! }.to change { Asset.all.count }.by(1).and change { Fact.count }
      end
    end
    context 'when the step type does have a step action' do
      let(:step_action) { 'some_action' }
      context 'when the step action runs correctly' do
        let(:valid_changes) { FactChanges.new.tap { |update| update.create_assets(['?p']) } }
        let(:correct_execution) do
          execution = double('step_execution')
          allow(execution).to receive(:plan).and_return(valid_changes)
          execution
        end
        before { allow(InferenceEngines::Runner::StepExecution).to receive(:new).and_return(correct_execution) }

        it 'runs the rule defined by the step type and the actions for the step action' do
          asset.reload

          step = create_instance(step_type, activity, group)
          expect { step.run! }.to change { Asset.all.count }.by(2).and change { Fact.count }
        end

        it 'prints the selected list of assets' do
          asset.reload

          step = create_instance(step_type, activity, group)

          expect_any_instance_of(AssetGroup).to receive(:print).with(printer_config)

          step.run!
        end

        # NOTE: We can probably safely remove this test entirely once the flag is permenant
        it 'does not print assets when dpl348_decouple_automatic_printing_from_steps is enabled' do
          Flipper.enable(:dpl348_decouple_automatic_printing_from_steps)
          asset.reload

          step = create_instance(step_type, activity, group)

          expect_any_instance_of(AssetGroup).not_to receive(:print).with(printer_config)

          step.run!
        end

        context 'when printing fails' do
          before do
            allow_any_instance_of(AssetGroup).to receive(:print).and_raise(
              PrintMyBarcodeJob::PrintingError,
              'The printer was stolen'
            )
          end

          let(:step) { create_instance(step_type, activity, group) }

          context 'and dpl348_steps_only_warn_on_print_failure is enabled' do
            before do
              allow_any_instance_of(Activity).to receive(:report_error)
              Flipper.enable :dpl348_steps_only_warn_on_print_failure
            end

            it 'runs the rest of the job', aggregate_failures: true do
              asset
              expect { step.run! }.to change(Asset, :count).by(2).and change(Fact, :count)
              expect(step).to be_complete, "Step #{step.state}, with output: #{step.output}"
            end

            it 'provides user feedback' do
              # Unfortunately because we are reloading the step, we can't use
              # expect(step.activity) as the two are different instances. We
              # *could* use ActionCable.server, but then we are coupling to the
              # implementation a bit more
              expect_any_instance_of(Activity).to receive(:report_error).with('Could not print: The printer was stolen')
              step.run!
            end
          end

          context 'and dpl348_steps_only_warn_on_print_failure is disabled' do
            it 'fails the rest of the job' do
              step.run!
              expect(step).to be_failed
            end
          end
        end
      end
      context 'when it has cancelled operations from previous failed executions' do
        let(:step) { create_instance(step_type, activity, group) }
        before do
          step.operations <<
            create(:operation, action_type: 'add_facts', asset: asset, predicate: 'a', object: 'tube', cancelled?: true)
        end
        it 'does not run the default step execution' do
          allow(InferenceEngines::Default::StepExecution).to receive(:new)
          step.run!
          expect(InferenceEngines::Default::StepExecution).not_to have_received(:new)
        end
        it 'remakes the operations' do
          expect(step).to receive(:remake_me)
          step.run!
        end
      end
      context 'when the step works fine but the step action fails' do
        let(:failable_execution) do
          execution = double('step_execution')
          execution
        end

        before do
          allow(failable_execution).to receive(:plan).and_raise('not good!!')
          allow(InferenceEngines::Runner::StepExecution).to receive(:new).and_return(failable_execution)
        end

        it 'cancels changes from the step' do
          asset.reload

          # We don't change asset count because assets are never destroyed, only facts
          step = create_instance(step_type, activity, group)
          expect { step.run! }.not_to change { Fact.count }
        end
      end
    end
  end
end
