module Activities
  module BackgroundTasks # rubocop:todo Style/Documentation
    class BackgroundTask # rubocop:todo Style/Documentation
      attr_accessor :step_type

      def initialize(step_type)
        @step_type = step_type
      end

      def create!(params)
        @step_type.class_for_task_type.send(:create!, params.merge(step_type: @step_type))
      end
    end

    def background_tasks
      return step_types.for_reasoning.map { |type| BackgroundTask.new(type) }
    end

    def create_background_steps(ordered_tasks, reasoning_params)
      ActiveRecord::Base.transaction do
        ordered_tasks.reduce([]) do |current_list, actual_task_class|
          actual_step = actual_task_class.create!(reasoning_params)
          current_list.last.update!(next_step: actual_step) unless current_list.empty?
          current_list.push(actual_step)
          current_list
        end
      end
    end

    def create_connected_tasks(step, asset_group, printer_config = nil, user = nil)
      reasoning_params = {
        asset_group: asset_group,
        activity: self,
        printer_config: printer_config,
        user: user,
        in_progress?: true
      }
      steps = create_background_steps(background_tasks, reasoning_params)
      step.update(next_step: steps.first)
      [step, steps].flatten.compact
    end
  end
end
