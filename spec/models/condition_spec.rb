require 'rails_helper'
require 'support_n3'

RSpec.describe Condition, type: :model do
  describe '#compatible_with' do
    setup do
      @wildcard = FactoryBot.create(:condition_group)
      @cond = FactoryBot.create(:condition, { predicate: 'aliquotType', object_condition_group: @wildcard })
      @fact = FactoryBot.create(:fact, { predicate: 'aliquotType', object: 'DNA' })
      @asset = FactoryBot.create(:asset, { facts: [@fact] })
    end

    it 'is compatible with a wildcard' do
      expect(@cond.compatible_with?(@asset)).to eq(true)
    end
  end

  describe 'wildcard creation on compatible_with()' do
    # assets, required_assets=nil, checked_condition_groups=[], wildcard_values={})
    setup do
      @assets =
        Array.new(5) do |i|
          facts = [FactoryBot.create(:fact, { predicate: 'a', object: 'Tube' })]
          aliquot = ((i % 2) == 0) ? 'DNA' : 'RNA'
          facts.push(FactoryBot.create(:fact, { predicate: 'aliquotType', object: aliquot }))
          FactoryBot.create(:asset, facts: facts)
        end

      @wells =
        Array.new(5) do |i|
          facts = [FactoryBot.create(:fact, { predicate: 'a', object: 'Well' })]
          aliquot = ((i % 2) == 0) ? 'DNA' : 'RNA'
          facts.push(FactoryBot.create(:fact, { predicate: 'aliquotType', object: aliquot }))
          FactoryBot.create(:asset, facts: facts)
        end
      @rack = FactoryBot.create :asset
      @rack.facts << (FactoryBot.create(:fact, { predicate: 'a', object: 'Rack' }))
      @rack.facts << (@wells.map { |well| FactoryBot.create(:fact, { predicate: 'contains', object_asset: well }) })

      @assets = @assets.push(@wells, @rack).flatten

      @step_type = FactoryBot.create :step_type
    end
    it 'generates the right wildcards' do
      rule =
        "{ \
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

      @asset_group = FactoryBot.create(:asset_group, assets: @assets)
      @step = FactoryBot.create(:step, { step_type: @step_type, asset_group: @asset_group })

      {
        210 => {
          1737 => ['DNA'],
          1738 => ['RNA'],
          1739 => ['DNA'],
          1740 => ['RNA'],
          1741 => ['DNA'],
          1742 => ['DNA'],
          1743 => ['RNA'],
          1744 => ['DNA'],
          1745 => ['RNA'],
          1746 => ['DNA']
        },
        211 => {
          1737 => ['DNA'],
          1738 => ['RNA'],
          1739 => ['DNA'],
          1740 => ['RNA'],
          1741 => ['DNA'],
          1742 => ['DNA'],
          1743 => ['RNA'],
          1744 => ['DNA'],
          1745 => ['RNA'],
          1746 => ['DNA']
        }
      }
    end
  end
end
