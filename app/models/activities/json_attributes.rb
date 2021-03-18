module Activities::JsonAttributes
  def initial_json_attributes(current_user = nil)
    {
       activity: {
         id: id,
         completed_at: completed_at,
         activity_type_name: activity_type.name,
         instrument_name: instrument ? (instrument.name || instrument.barcode) : nil,
         kit_name: kit ? kit.barcode : nil,
         selectedAssetGroup: owned_asset_groups.first.id
       },
      tubePrinter: {
        optionsData: Printer.for_tube.map { |a| [a.name, a.id] },
        defaultValue: current_user && current_user.tube_printer ? current_user.tube_printer.id : nil
      },
      platePrinter: {
        optionsData: Printer.for_plate.map { |a| [a.name, a.id] },
        defaultValue: current_user && current_user.plate_printer ? current_user.plate_printer.id : nil
      }
    }.merge(websockets_attributes(json_attributes))
  end

  def json_attributes
    running_activity = running? || editing?
    {
      activityRunning: -> { running? || editing? },
      activityState: -> { state },
      messages: -> { ApplicationController.helpers.messages_for_activity(self) },
      assetGroups: -> { ApplicationController.helpers.asset_groups_data(self) },
      dataAssetDisplay: -> { ApplicationController.helpers.data_asset_display_for_activity(self) },
      stepTypes: -> { ApplicationController.helpers.step_types_control_data(self) },
      stepsPending: -> { ApplicationController.helpers.steps_data_for_steps(self.steps.running) },
      stepsRunning: -> { ApplicationController.helpers.steps_data_for_steps(self.steps.processing) },
      stepsFailed: -> { ApplicationController.helpers.steps_data_for_steps(self.steps.finished.select { |s| s.state == 'failed' }) },
      stepsFinished: -> { ApplicationController.helpers.steps_data_for_steps(self.steps.reload.finished.reverse) }
    }
  end
end
