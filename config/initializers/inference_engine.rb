Rails.application.routes.default_url_options[:host] = Rails.configuration.default_n3_resources_url

if Rails.configuration.inference_engine == :cwm
  raise 'Not found CWM' unless Rails.configuration.cwm_path

  require 'inference_engines/cwm/step_execution'
  StepExecution = InferenceEngines::Cwm::StepExecution
else
  require 'inference_engines/default/step_execution'
  StepExecution = InferenceEngines::Default::StepExecution
end
