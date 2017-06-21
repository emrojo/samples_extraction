# frozen_string_literal: true
require 'inference_engines/default/actions/asset_actions'
require 'inference_engines/default/actions/fact_actions'
require 'inference_engines/default/actions/operation_actions'
require 'inference_engines/default/actions/service_actions'

module InferenceEngines
  module Default
    class StepExecution
      include Actions::AssetActions
      include Actions::FactActions
      include Actions::OperationActions
      include Actions::ServiceActions

      # Elements not modified during all lifetime of StepExecution instance
      attr_accessor :step
      attr_accessor :asset_group
      attr_accessor :original_assets

      # Elements not modified during 1 execution
      attr_accessor :asset
      attr_accessor :position
      attr_accessor :action

      # Elements modified in every execution:

      # Assets that have changed in this execution
      attr_accessor :changed_assets
      # Facts modified for the changed assets
      attr_accessor :changed_facts
      # Assets created during all the executions
      attr_accessor :created_assets
      # List of facts that will be destroyed in a single DELETE sql
      attr_accessor :facts_to_destroy
      # Hash with the positions for each asset by condition group
      attr_accessor :positions_for_asset

      ACTION_TYPES = %w(addFacts removeFacts createAsset selectAsset updateService).freeze

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets = params[:original_assets]
        @created_assets = params[:created_assets]
        @facts_to_destroy = params[:facts_to_destroy]
      end

      def valid_action_type?
        ACTION_TYPES.include?(action.action_type)
      end

      # Identifies which asset acting as subject is compatible with which rule.
      def classify_assets
        perform_list = []

        @positions_for_asset = step.step_type.position_for_assets_by_condition_group(asset_group.assets)

        step.step_type.actions.includes([:subject_condition_group, :object_condition_group]).each do |r|
          if r.subject_condition_group.nil?
            raise RelationSubject, 'A subject condition group needs to be specified to apply the rule'
          end
          if r.object_condition_group && !r.object_condition_group.is_wildcard?
            unless [r.subject_condition_group, r.object_condition_group].any? { |c| c.cardinality == 1 }
              # Because a condition group can refer to an unknown number of assets,
              # when a rule relates 2 condition groups (?p :transfers ?q) we cannot
              # know how to connect their assets between each other unless at least
              # one of the condition groups has maxCardinality set to 1
              msg = ['In a relation between condition groups, one of them needs to have ',
                     'maxCardinality set to 1 to be able to infer how to connect its assets'].join('')
              # raise RelationCardinality, msg
            end
          end
          # If this condition group is referring to an element not matched (like
          # a new created asset, for example) I cannot classify my assets with it
          if !step.step_type.condition_groups.include?(r.subject_condition_group)
            perform_list.push([nil, r])
          else
            asset_group.assets.includes(:facts).each do |asset|
              if r.subject_condition_group.compatible_with?(asset)
                perform_list.push([asset, r, positions_for_asset[asset][r.subject_condition_group]])
              end
            end
          end
        end
        perform_list.sort do |a, b|
          if a[1].action_type == 'createAsset'
            -1
          elsif b[1].action_type == 'createAsset'
            1
          else
            a[1].action_type <=> b[1].action_type
          end
        end
      end

      def perform_action(action, asset, position)
        # puts "action=#{action.action_type}, asset=#{asset.name}, position=#{position}"
        @asset = asset
        @position = position
        @action = action

        @changed_assets = [asset]
        @changed_facts = nil
        if action.subject_condition_group.conditions.empty?
          @changed_assets = created_assets[action.subject_condition_group.id]
        end

        send(action.action_type.underscore) if valid_action_type?
      end

      def run
        classify_assets.each do |asset, action, position|
          if step.step_type.connect_by == 'position'
            perform_action(action, asset, position)
          else
            perform_action(action, asset, nil)
          end
        end
        save_created_assets
      end
    end
  end
end
