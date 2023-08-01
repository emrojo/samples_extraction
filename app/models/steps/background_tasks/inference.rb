require 'inference_engines/cwm/step_execution'

class Steps::BackgroundTasks::Inference < Step # rubocop:todo Style/Documentation
  def process
    inferences =
      InferenceEngines::Cwm::StepExecution.new(
        step: self,
        asset_group: asset_group,
        created_assets: {},
        step_types: [step_type]
      )
    inferences.run
  end
end
