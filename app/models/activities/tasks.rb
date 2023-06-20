module Activities
  module Tasks # rubocop:todo Style/Documentation
    def create_step(params)
      params[:step_type]
        .class_for_task_type
        .create!(
          activity: self,
          printer_config: params[:printer_config],
          step_type: params[:step_type],
          asset_group: params[:asset_group],
          user: params[:user]
        )
        .tap do |step|
          create_connected_tasks(step, params[:asset_group], params[:printer_config], params[:user])
          step.run!
        end
    end
  end
end
