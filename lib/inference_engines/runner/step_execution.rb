require 'step_execution_process'
require 'open3'

module InferenceEngines
  module Runner
    class StepExecution
      include StepExecutionProcess

      attr_accessor :step, :asset_group, :original_assets,
        :created_assets, :facts_to_destroy, :updates, :content

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets= params[:original_assets]
        @created_assets= params[:created_assets]
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

      def run_from_class
        require("#{Rails.root}/script/runners/#{@step.step_type.step_action}")
        @content = @step.step_type.step_action.gsub("\.rb", '').camelize.constantize.new(asset_group: @asset_group, step: @step).process.to_json
        step.update_columns(output: @content)
        @updates = FactChanges.new(@content)
      end

      def generate_plan
        return generate_plan2
        if @step.step_type.actions.length > 0
          run_from_class
        else
          generate_plan2
        end
      end

      def generate_plan2
        if @step.step_type.step_action.match(/\.rb$/)
          cmd = ["bin/rails", "runner", "#{Rails.root}/script/runners/#{@step.step_type.step_action}"]
        else
          cmd = "#{Rails.root}/script/runners/#{@step.step_type.step_action}"
        end

        call_list = [
          cmd,
          input_url = Rails.application.routes.url_helpers.asset_group_url(@asset_group.id)+".json",
          step_url = Rails.application.routes.url_helpers.step_url(@step.id)+".json"
        ].flatten

        call_str = call_list.join(" ")

        line = "# EXECUTING: #{call_str}"

        Open3.popen3(*[call_list].flatten) do |stdin, stdout, stderror, thr|
          @content = stdout.read
          output = [line, content].join("\n")
          step.update_attributes(output: output)
          unless thr.value==0
            raise "runner execution failed\nCODE: #{thr.value}\nCMD: #{line}\nSTDOUT: #{content}\nSTDERR: #{stderror.read}\n"
          end
        end

        @updates=FactChanges.new(@content)
      end

      def plan
        generate_plan

        debug_log step.output
        updates
      end

      def apply
        if asset_group.assets.with_fact('pushTo', 'Sequencescape').count > 0
          asset_group.assets.with_fact('pushTo', 'Sequencescape').each do |asset|
            @updates.merge(asset.update_sequencescape(step.printer_config, step.user, step))
          end
        end
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
        FactChanges.new.tap do |updates|
          list.each { |l| updates.add(l[0], l[1], l[2]) }
        end
      end

      def remove_facts(list)
        FactChanges.new.tap do |updates|
          list.each { |l| updates.remove_where(l[0], l[1], l[2]) }
        end
      end

      def delete_asset(list)
        FactChanges.new.tap do |updates|
          updates.delete_assets(list)
        end
      end

      def create_asset(list)
        FactChanges.new.tap do |updates|
          updates.create_assets(list)
        end
      end

      def select_asset(uuids)
        FactChanges.new.tap do |updates|
          assets = uuids.map { |uuid| Asset.find_by(uuid: uuid) }
          updates.add_assets(@step.asset_group.id, uuids)
          #@step.asset_group.add_assets(assets)
        end
      end

      def unselect_asset(uuids)
        FactChanges.new.tap do |updates|
          assets = uuids.map { |uuid| Asset.find_by(uuid: uuid) }
          updates.remove_assets(@step.asset_group.id, uuids)
          #@step.asset_group.remove_assets(assets)
        end
      end
    end
  end
end
