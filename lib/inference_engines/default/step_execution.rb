require 'step_execution_process'
require 'fact_changes'

module InferenceEngines
  module Default
    class StepExecution # rubocop:todo Style/Documentation
      include StepExecutionProcess

      attr_accessor :step, :asset_group, :updates

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @updates = FactChanges.new
      end

      def compatible?
        refresh
        true
      end

      def executable_actions_sorted
        step
          .step_type
          .actions
          .includes(%i[subject_condition_group object_condition_group])
          .sort do |a, b|
            %i[create_asset add_facts remove_facts delete_asset select_asset unselect_asset]
            if a.action_type == 'createAsset'
              -1
            elsif b.action_type == 'createAsset'
              1
            else
              a.action_type <=> b.action_type
            end
          end
      end

      def unselect_assets_with_conditions(condition_groups, updates)
        condition_groups.each do |condition_group|
          unless condition_group.keep_selected
            unselect_assets =
              asset_group.assets.includes(:facts).select { |asset| condition_group.compatible_with?(asset) }
            updates.remove_assets([[unselect_assets].flatten]) if unselect_assets
          end
        end
      end

      def refresh
        asset_group.assets.each(&:refresh)
      end

      def plan
        @updates =
          executable_actions_sorted.reduce(updates) do |updates, action|
            action.run(asset_group, step.wildcard_values).merge(updates)
          end

        step.step_type.condition_groups.each do |cg|
          if cg.keep_selected != true
            updates.remove_assets([[asset_group, asset_group.classified_by_condition_group(cg)]])
          end
        end

        unselect_assets_with_conditions(step.step_type.condition_groups, updates)
        unselect_assets_with_conditions(step.step_type.action_subject_condition_groups, updates)
        unselect_assets_with_conditions(step.step_type.action_object_condition_groups, updates)
        updates
      end

      def apply
        updates.apply(step)
      end
    end
  end
end
