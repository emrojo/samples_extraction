require 'inference_engines/runner/step_execution'

class Steps::BackgroundTasks::Runner < Step # rubocop:todo Style/Documentation
  def process
    runner =
      InferenceEngines::Runner::StepExecution.new(
        step: self,
        asset_group: asset_group,
        created_assets: {},
        step_types: [step_type]
      )
    runner.run
  end
end
