require 'inference_engines/runner/step_execution'
module Steps::Task # rubocop:todo Style/Documentation
  def process
    if operations.count > 0
      remake_me
      updates = FactChanges.new
    else
      # StepExecution here will either be InferenceEngines::Cwm::StepExecution or
      # InferenceEngines::Default::StepExecution depending on the configuration
      # parameter Rails.configuration.inference_engine which appears to be set to
      # Default.
      step_execution = StepExecution.new(step: self, asset_group: asset_group)
      updates = step_execution.plan
      return stop! unless apply_changes(updates)
    end

    assets_for_printing = updates.assets_for_printing unless Flipper.enabled?(
      :dpl348_decouple_automatic_printing_from_steps
    )

    unless step_type.step_action.nil? || step_type.step_action.empty?
      runner =
        InferenceEngines::Runner::StepExecution.new(
          step: self,
          asset_group: asset_group,
          created_assets: {},
          step_types: [step_type]
        )

      updates = runner.plan

      return stop! unless apply_changes(updates)

      assets_for_printing = assets_for_printing.to_a.concat(updates.assets_for_printing) unless Flipper.enabled?(
        :dpl348_decouple_automatic_printing_from_steps
      )
    end

    return if Flipper.enabled?(:dpl348_decouple_automatic_printing_from_steps)

    if Flipper.enabled?(:dpl348_steps_only_warn_on_print_failure)
      print_asset_labels(assets_for_printing)
    else
      # Want to make this as easy and obvious to remove as possible
      # rubocop:disable Style/IfInsideElse
      AssetGroup.new(assets: assets_for_printing).print(printer_config) if assets_for_printing.length > 0

      # rubocop:enable Style/IfInsideElse
    end
  end

  def print_asset_labels(assets_for_printing)
    return if assets_for_printing.empty?

    AssetGroup.new(assets: assets_for_printing).print(printer_config)
  rescue PrintMyBarcodeJob::PrintingError => e
    report_error("Could not print: #{e.message}")
  end

  def apply_changes(updates)
    reload
    return false if stopped?

    updates.apply(self)
    true
  end
end
