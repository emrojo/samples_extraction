# frozen_string_literal: true
require 'rails_helper'
require 'spec_helper'
require Rails.root.join 'spec/concerns/deprecatable_spec.rb'

def assert_equal(a, b)
  expect(a).to eq(b)
end

RSpec.describe StepType, type: :model do
  it_behaves_like 'deprecatable'

  describe '#compatible_with' do
    setup do
      @step_type = FactoryGirl.create :step_type
      @cg1 = FactoryGirl.create(:condition_group, name: 'p')
      @step_type.condition_groups << @cg1
      @cg1.conditions << FactoryGirl.create(:condition,                                               predicate: 'is', object: 'Tube')
      @cg1.conditions << FactoryGirl.create(:condition,                                               predicate: 'is', object: 'Full')

      @asset = FactoryGirl.create :asset
    end

    describe 'matching no assets' do
      it 'is not compatible with an empty list' do
        assert_equal false, @step_type.compatible_with?([])
        assert_equal false, @step_type.compatible_with?(nil)
        assert_equal false, @step_type.compatible_with?({})
      end
    end

    describe 'matching one asset' do
      setup do
        @asset = FactoryGirl.create :asset
      end

      it 'is compatible with a totally compatible asset' do
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Tube')
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Full')

        assert_equal true, @step_type.compatible_with?(@asset)
      end

      it 'is incompatible with a partially compatible asset' do
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Tube')

        assert_equal false, @step_type.compatible_with?(@asset)
      end

      it 'is incompatible with a partially incompatible asset' do
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Tube')
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Empty')

        assert_equal false, @step_type.compatible_with?(@asset)
      end

      it 'is not compatible with an incompatible asset' do
        @asset.facts << FactoryGirl.create(:fact, predicate: 'is', object: 'Rack')

        assert_equal false, @step_type.compatible_with?(@asset)
      end

      describe 'with special configuration' do
        describe 'related with cardinality' do
          setup do
            @assets = Array.new(5) do |_i|
              FactoryGirl.create :asset, facts: [
                FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
                FactoryGirl.create(:fact, predicate: 'is', object: 'Full')
              ]
            end
          end

          it 'is compatible with any number of assets with no cardinality check' do
            @cg1.cardinality = nil

            assert_equal true, @step_type.compatible_with?(@assets)
          end

          it 'is compatible when number of assets is below the maximum cardinality' do
            @cg1.cardinality = 10
            assert_equal true, @step_type.compatible_with?(@assets)
          end

          it 'is compatible when number of assets is equal to the maximum cardinality' do
            @cg1.cardinality = 5
            assert_equal true, @step_type.compatible_with?(@assets)
          end

          it 'is incompatible when number of assets overpasses the maximum cardinality' do
            @cg1.cardinality = 4
            assert_equal false, @step_type.compatible_with?(@assets)
          end
        end
      end
    end
    describe 'matching more than one asset' do
      describe 'for the same condition group' do
        setup do
          @assets = Array.new(5) do |_i|
            FactoryGirl.create :asset, facts: [
              FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
              FactoryGirl.create(:fact, predicate: 'is', object: 'Full')
            ]
          end
        end

        it 'is compatible if all the assets match all the conditions of the rule' do
          @assets.first.facts << FactoryGirl.create(:fact,
                                                    predicate: 'has', object: 'DNA')
          assert_equal true, @step_type.compatible_with?(@assets)
        end

        it 'is not compatible if any of the assets do not match any the conditions of the rule' do
          @assets << FactoryGirl.create(:asset, facts: [
                                          FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
                                          FactoryGirl.create(:fact, predicate: 'is', object: 'Empty')
                                        ])
          assert_equal false, @step_type.compatible_with?(@assets)
        end
        it 'is not compatible if any of the assets do not match all the conditions of the rule' do
          @assets << FactoryGirl.create(:asset, facts: [
                                          FactoryGirl.create(:fact, predicate: 'is', object: 'Rack'),
                                          FactoryGirl.create(:fact, predicate: 'is', object: 'Empty')
                                        ])
          assert_equal false, @step_type.compatible_with?(@assets)
        end
      end

      describe 'for different condition groups' do
        setup do
          @cg2 = FactoryGirl.create(:condition_group, name: 'q')
          @cg2.conditions << FactoryGirl.create(:condition, predicate: 'is',
                                                            object: 'Rack')

          @step_type.condition_groups << @cg2

          @assets = Array.new(5) do |_i|
            FactoryGirl.create :asset, facts: [
              FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
              FactoryGirl.create(:fact, predicate: 'is', object: 'Full')
            ]
          end

          @racks = Array.new(5) do |_i|
            FactoryGirl.create :asset, facts: [
              FactoryGirl.create(:fact, predicate: 'is', object: 'Rack')
            ]
          end
        end

        it 'is compatible with both condition groups when cardinality was set for one of them' do
          racks = @racks.slice(0, 3)
          @cg2.cardinality = 3

          assert_equal true, @step_type.compatible_with?([@assets, racks].flatten)
        end

        it 'is compatible if all the condition groups are matched by the assets' do
          assert_equal true, @step_type.compatible_with?([@assets, @racks].flatten)
          @assets.first.facts << FactoryGirl.create(:fact, predicate: 'a', object: 'b')
          assert_equal true, @step_type.compatible_with?([@assets, @racks].flatten)
        end

        it 'is not compatible if any the condition groups are not matched by the assets' do
          assert_equal false, @step_type.compatible_with?(@racks)
          assert_equal false, @step_type.compatible_with?(@assets)
        end

        it 'is not compatible if none of the condition groups are matched by the assets' do
          a = FactoryGirl.create :asset
          a.facts << FactoryGirl.create(:fact, predicate: 'a', object: 'b')
          b = FactoryGirl.create :asset
          b.facts << FactoryGirl.create(:fact, predicate: 'c', object: 'd')
          assert_equal false, @step_type.compatible_with?([a, b].flatten)
        end

        it 'is not compatible if any of the condition groups is partially matched by any of the assets' do
          @assets.last.facts = [FactoryGirl.create(:fact, predicate: 'is', object: 'Tube')]
          assert_equal false, @step_type.compatible_with?([@assets, @racks].flatten)
        end

        describe 'with assets that overlap between condition groups' do
          it 'is compatible with overlapped assets' do
            @tubes_and_racks = Array.new(7) do
              FactoryGirl.create(:asset, facts: [
                                   FactoryGirl.create(:fact, predicate: 'is', object: 'Rack'),
                                   FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
                                   FactoryGirl.create(:fact, predicate: 'is', object: 'Full')
                                 ])
            end
            assert_equal true, @step_type.compatible_with?([@assets, @racks, @tubes_and_racks].flatten)
          end
        end
      end
    end

    describe 'matching related assets' do
      setup do
        @cg2 = FactoryGirl.create(:condition_group, {})
        @cg2.conditions << FactoryGirl.create(:condition, predicate: 'is', object: 'Rack')

        @step_type.condition_groups << @cg2

        @cg1.conditions << FactoryGirl.create(:condition, predicate: 'inRack', object: 'q',
                                                          object_condition_group_id: @cg2.id)

        @racks = Array.new(5) do |_i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Rack')
          ]
        end

        @bad_racks = Array.new(5) do |_i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Rack')
          ]
        end

        @assets = Array.new(5) do |i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
            FactoryGirl.create(:fact, predicate: 'is', object: 'Full'),
            FactoryGirl.create(:fact, predicate: 'inRack', object_asset_id: @racks[i].id)
          ]
        end
      end
      it 'is compatible with condition groups that have relations with elements included in the asset group' do
        assert_equal true, @step_type.compatible_with?([@assets, @racks].flatten)
      end
      it 'is not compatible when the relation is not matching the conditions required' do
        @bad_racks = Array.new(5) do |_i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'BadRack')
          ]
        end

        @assets = Array.new(5) do |i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
            FactoryGirl.create(:fact, predicate: 'is', object: 'Full'),
            FactoryGirl.create(:fact, predicate: 'inRack', object_asset_id: @bad_racks[i].id)
          ]
        end
        assert_equal false, @step_type.compatible_with?([@assets, @bad_racks].flatten)
      end
      it 'is compatible with condition groups that have relations with elements outside the asset group' do
        assert_equal true, @step_type.compatible_with?(@assets)
      end
    end
    describe 'matching with wildcard condition groups' do
      setup do
        @cg2 = FactoryGirl.create(:condition_group, {})
        @cg1.conditions << FactoryGirl.create(:condition, predicate: 'position',
                                                          object_condition_group_id: @cg2.id)
      end
      it 'is compatible with any literal when met the other conditions' do
        @assets = Array.new(5) do |i|
          FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Tube'),
            FactoryGirl.create(:fact, predicate: 'is', object: 'Full'),
            FactoryGirl.create(:fact, predicate: 'position', object: i)
          ]
        end
        assert_equal true, @step_type.compatible_with?([@assets].flatten)
      end
    end
  end
end
