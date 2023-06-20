require 'step_execution_process'
require 'open3'

module InferenceEngines
  module Runner
    class StepExecution # rubocop:todo Style/Documentation
      include StepExecutionProcess

      attr_accessor :step, :asset_group, :original_assets, :created_assets, :facts_to_destroy, :updates, :content

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets = params[:original_assets]
        @created_assets = params[:created_assets]
        @facts_to_destroy = params[:facts_to_destroy]

        @step_types = params[:step_types] || [@step.step_type]
        @updates = params[:updates] || FactChanges.new
      end

      def debug_log(params)
        puts params
        if Rails.logger
          Rails.logger.debug(params)
        else
          @log = Logger.new(STDOUT) unless @log
          @log.debug(params)
        end
      end

      def step_action
        @step.step_type.step_action
      end

      def handled_by_class?
        step_action.starts_with?('StepPlanner::')
      end

      def generate_plan
        handled_by_class? ? generate_plan_from_class : generate_plan_from_external_process
      end

      def generate_plan_from_class
        klass = step_action.constantize

        step_planner = klass.new(@asset_group.id, @step.id)
        @content = step_planner.updates
        step.update(output: @content)
        @updates = @content
      end

      def generate_plan_from_external_process
        if step_action.end_with?('.rb')
          cmd = ['bin/rails', 'runner', "#{Rails.root}/script/runners/#{step_action}"]
        else
          cmd = "#{Rails.root}/script/runners/#{step_action}"
        end

        call_list = [cmd, input_url, step_url].flatten

        call_str = call_list.join(' ')

        line = "# EXECUTING: #{call_str}"
        Open3.popen3(*[call_list].flatten) do |_stdin, stdout, stderror, thr|
          @content = stdout.read
          output = [line, content].join("\n")
          step.update(output: output)
          unless thr.value == 0
            # rubocop:todo Layout/LineLength
            raise "runner execution failed\nCODE: #{thr.value}\nCMD: #{line}\nSTDOUT: #{content}\nSTDERR: #{stderror.read}\n"
            # rubocop:enable Layout/LineLength
          end
        end

        @updates = FactChanges.new(@content)
      end

      def plan
        generate_plan

        debug_log step.output
        updates
      end

      def apply
        asset_group
          .assets
          .with_fact('pushTo', 'Sequencescape')
          .each { |asset| @updates.merge(asset.update_sequencescape(step.user)) }
        @updates.apply(step)
      end

      def refresh
        @asset_group.assets.each(&:refresh)
      end

      def compatible?
        refresh
        return true if step.step_type.condition_groups.count == 0

        step.step_type.compatible_with?(@asset_group.assets)
      end

      def add_facts(list)
        FactChanges.new.tap { |updates| list.each { |l| updates.add(l[0], l[1], l[2]) } }
      end

      def remove_facts(list)
        FactChanges.new.tap { |updates| list.each { |l| updates.remove_where(l[0], l[1], l[2]) } }
      end

      def delete_asset(list)
        FactChanges.new.tap { |updates| updates.delete_assets(list) }
      end

      def create_asset(list)
        FactChanges.new.tap { |updates| updates.create_assets(list) }
      end

      def select_asset(uuids)
        FactChanges.new.tap do |updates|
          assets = uuids.map { |uuid| Asset.find_by(uuid: uuid) }
          updates.add_assets(@step.asset_group.id, uuids)
          # @step.asset_group.add_assets(assets)
        end
      end

      def unselect_asset(uuids)
        FactChanges.new.tap do |updates|
          assets = uuids.map { |uuid| Asset.find_by(uuid: uuid) }
          updates.remove_assets(@step.asset_group.id, uuids)
          # @step.asset_group.remove_assets(assets)
        end
      end

      private

      def input_url
        Rails.application.routes.url_helpers.asset_group_url(@asset_group.id) + '.json'
      end

      def step_url
        Rails.application.routes.url_helpers.step_url(@step.id) + '.json'
      end
    end
  end
end
