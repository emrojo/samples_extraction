# frozen_string_literal: true
require 'rails_helper'
require 'support_n3'

RSpec.describe Condition, type: :model do
  describe 'wildcard creation on compatible_with()' do
    # assets, required_assets=nil, checked_condition_groups=[], wildcard_values={})
    setup do
      @assets = Array.new(5) do |i|
        facts = [
          FactoryGirl.create(:fact, predicate: 'a', object: 'Tube')
        ]
        aliquot = i.even? ? 'DNA' : 'RNA'
        facts.push(FactoryGirl.create(:fact, predicate: 'aliquotType', object: aliquot))
        FactoryGirl.create(:asset, facts: facts)
      end

      @wells = Array.new(5) do |i|
        facts = [
          FactoryGirl.create(:fact, predicate: 'a', object: 'Well')
        ]
        aliquot = i.even? ? 'DNA' : 'RNA'
        aliquot = 'RNA'
        facts.push(FactoryGirl.create(:fact, predicate: 'aliquotType', object: aliquot))
        FactoryGirl.create(:asset, facts: facts)
      end
      @rack = FactoryGirl.create :asset
      @rack.add_facts(FactoryGirl.create(:fact, predicate: 'a', object: 'Rack'))
      @rack.add_facts(@wells.map { |well| FactoryGirl.create(:fact, predicate: 'contains', object_asset: well) })

      @assets = @assets.concat([@wells, @rack]).flatten

      @step_type = FactoryGirl.create :step_type
    end
    it 'uses the wildcards to apply the step' do
      rule = "{ \
        ?p :a :Tube . \
        ?p :aliquotType ?_x . \
        ?s :a :Tube . \
        ?s :aliquotType ?_y . \
        ?q :a :Rack . \
        ?q :contains ?r . \
        ?r :aliquotType ?_x . \
        ?q :contains ?t . \
        ?t :aliquotType ?_y . }\
      => {\
        :step :addFacts { ?p :sameAliquot ?q .  }\
      } ."

      SupportN3.parse_string(rule, {}, @step_type)
      checked = []
      wildcards = {}
      expect(@step_type.compatible_with?(@assets, nil, checked, wildcards)).to eq(true)

      @asset_group = FactoryGirl.create(:asset_group, assets: @assets)

      created_assets = {}
      @step_execution = StepExecution.new(step: Step.new(step_type: @step_type, asset_group: @asset_group),
                                          asset_group: @asset_group, created_assets: created_assets)
      @step_execution.run

      { 210 => { 1737 => ['DNA'], 1738 => ['RNA'],
                 1739 => ['DNA'], 1740 => ['RNA'], 1741 => ['DNA'],
                 1742 => ['DNA'], 1743 => ['RNA'], 1744 => ['DNA'],
                 1745 => ['RNA'], 1746 => ['DNA'] },
        211 => { 1737 => ['DNA'],
                 1738 => ['RNA'], 1739 => ['DNA'], 1740 => ['RNA'],
                 1741 => ['DNA'], 1742 => ['DNA'], 1743 => ['RNA'],
                 1744 => ['DNA'], 1745 => ['RNA'], 1746 => ['DNA'] } }
    end
  end
end
