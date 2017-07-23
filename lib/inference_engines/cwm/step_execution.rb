module InferenceEngines
  module Cwm
    class StepExecution
      attr_accessor :step, :asset_group, :original_assets, :created_assets, :facts_to_destroy

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets= params[:original_assets]
        @created_assets= params[:created_assets]
        @facts_to_destroy = params[:facts_to_destroy]

        @step_types = params[:step_types] || [@step.step_type]
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

      def run
        output_tempfile = Tempfile.new('out_datainfer')
        input_urls = [
          Rails.application.routes.url_helpers.asset_group_url(@asset_group.id),
          @step_types.map do |step_type|
            Rails.application.routes.url_helpers.step_type_url(step_type.id)
          end
        ].flatten.join(" ")

        unless system("#{Rails.configuration.cwm_path}/cwm #{input_urls} --mode=r --think > #{output_tempfile.path}")
          raise 'cwm rules failed!!'
        end

        debug_log `cat #{output_tempfile.path}`
        step_actions = SupportN3::load_step_actions(output_tempfile)

        ['create_asset', 'remove_facts', 'add_facts', 'unselect_asset', 'select_asset'].each do |action_type|
          quads = step_actions[action_type.camelize(:lower).to_sym]
          send(action_type, quads) if quads
        end
      end

      def self.UUID_REGEXP
        /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      end

      def is_uuid?(str)
        str.match(self.class.UUID_REGEXP)
      end

      def uuid(str)
        str.match(self.class.UUID_REGEXP)[0]
      end

      def fragment(k)
        SupportN3::fragment(k)
      end

      def add_facts(graphs)
        graphs.each do |quads|
          quads.map do |quad|
            asset = Asset.find_by!(:uuid => uuid(fragment(quad[0])))
            add_quad_to_asset(quad,asset)
          end
        end
      end

      def equal_quad_and_fact?(quad, fact)
        return false if fact.predicate != fragment(quad[1])
        object = fragment(quad[2])
        if is_uuid?(object)
          return true if fact.object_asset == Asset.find_by(:uuid => uuid(object))
        else
          return true if fact.object == object
        end
        return false
      end

      def remove_facts(graphs)
        graphs.each do |quads|
          quads.map do |quad|
            asset = Asset.find_by!(:uuid => uuid(fragment(quad[0])))
            asset.remove_facts(asset.facts.select do |f|
              equal_quad_and_fact?(quad, f)
            end) do |f|
              asset.add_operations([f], @step, 'removeFacts')
            end
          end
        end
      end

      def add_quad_to_asset(quad, asset, action_type="addFacts")
        object = fragment(quad[2])
        object_asset = nil
        literal = true
        if is_uuid?(object) || quad[2].uri?
          object_asset = Asset.find_by(:uuid => uuid(object))
          literal = false if object_asset
        end
        asset.add_facts(Fact.new(:predicate => fragment(quad[1]), :object => object, 
          :object_asset => object_asset, :literal => literal)) do |f|
          asset.add_operations([f], @step, action_type)
        end
      end

      def create_asset(graphs)
        if @step.created_asset_group.nil?
          @step.created_asset_group = AssetGroup.create(:activity_owner => @step.activity)
        end
        created_assets = {}
        graphs.each do |quads|
          quads.each do |quad|
            created_assets[quad[0]] = [ Asset.create! ].flatten unless created_assets[quad[0]]
            @step.asset_group.add_assets(created_assets[quad[0]])
            created_assets[quad[0]].each do |asset|
              add_quad_to_asset(quad, asset, "createAsset")
            end
          end
        end
        @step.created_asset_group.add_assets(created_assets.values.flatten.compact.uniq)
      end

      def select_asset(assets, quads)
        @step.asset_group.add_assets(assets)
      end

      def unselect_asset(assets, quads)
        @step.asset_group.remove_assets(assets)
      end
    end
  end
end