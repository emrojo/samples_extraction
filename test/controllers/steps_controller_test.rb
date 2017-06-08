# frozen_string_literal: true
require 'test_helper'

class StepsControllerTest < ActionController::TestCase
  setup do
    @controller = StepsController.new
  end

  context 'when performing an activity' do
    setup do
      @user = FactoryGirl.create :user
      @user.generate_token

      session[:token] = @user.token

      @asset = FactoryGirl.create :asset, barcode: '1111'
      @asset_group = FactoryGirl.create :asset_group
      @activity_type = FactoryGirl.create :activity_type
      @activity = FactoryGirl.create :activity, activity_type: @activity_type, asset_group: @asset_group
      @step_type = FactoryGirl.create :step_type
      @activity_type.step_types << @step_type
    end

    should 'create a new step inside the activity' do
      count = Step.all.count

      post :create, { activity_id: @activity.id, step_type_id: @step_type.id,
                      step: { state: 'done' } },
           session: { token: @user.token }
      assert_equal Step.all.count, count + 1
    end

    context 'POST /activities/:activity/step_types/:step_type/steps' do
      should "create a new step with status 'done' when no parameters are provided" do
        c = Step.all.count

        post :create, activity_id: @activity.id, step_type_id: @step_type.id,
                      step: { state: 'done' }
        Step.all.reload
        assert_equal Step.all.count, c + 1
        assert_equal false, Step.last.in_progress?
      end

      should 'execute a rule with different relations in between' do
        c = Step.all.count
        rule = '{ ' \
                  '?a :is :A . ' \
                  '?a :transfer ?b . ' \
                  '?b :is :B . ' \
                  '?b :transfer ?c . ' \
                  '?c :is :C . ' \
                  '?c :transfer ?d . ' \
                  '?d :is :D . ' \
                  '?d :transfer ?a . ' \
                '} => {' \
                  ':step :addFacts { ?a :is :Processed .}. ' \
                  ':step :addFacts { ?b :is :Processed .}. ' \
                  ':step :addFacts { ?c :is :Processed .}. ' \
                  ':step :addFacts { ?d :is :Processed .}. ' \
                  ':step :addFacts { ?a :transitiveRelation ?d .}. ' \
                '} .'

        # skip('this rule is unsupported as condition_group.compatible_with? does not support loops while following relations')
        SupportN3.parse_string(rule, {}, @step_type)
        assets = []
        assets.push(FactoryGirl.create(:asset, facts: [
                                         FactoryGirl.create(:fact, predicate: 'is', object: 'A'),
                                         FactoryGirl.create(:fact, predicate: 'position', object: '7')
                                       ]))
        assets.push(FactoryGirl.create(:asset, facts: [
                                         FactoryGirl.create(:fact, predicate: 'is', object: 'B')
                                       ]))
        assets.push(FactoryGirl.create(:asset, facts: [
                                         FactoryGirl.create(:fact, predicate: 'is', object: 'C')
                                       ]))
        assets.push(FactoryGirl.create(:asset, facts: [
                                         FactoryGirl.create(:fact, predicate: 'is', object: 'D')
                                       ]))

        assets[0].facts << FactoryGirl.create(:fact, predicate: 'transfer', object_asset: assets[1])
        assets[1].facts << FactoryGirl.create(:fact, predicate: 'transfer', object_asset: assets[2])
        assets[2].facts << FactoryGirl.create(:fact, predicate: 'transfer', object_asset: assets[3])
        assets[3].facts << FactoryGirl.create(:fact, predicate: 'transfer', object_asset: assets[0])

        @asset_group.update_attributes(assets: assets)
        @activity.update_attributes(asset_group: @asset_group)

        post :create, activity_id: @activity.id, step_type_id: @step_type.id, step: { data_params: '{}' }
        Step.all.reload
        assert_equal Step.all.count, c + 1
        assert_equal false, Step.last.in_progress?

        assert_equal true, assets.all? do |asset|
          asset.facts.reload
          (asset.facts.with_fact('is', 'processed').count == 1)
        end

        assets.each(&:reload)
        relation = assets[0].facts.with_predicate('transitiveRelation').first
        candidate_asset_d = relation.object_asset
        assert_equal true, candidate_asset_d.has_literal?('is', 'D')
      end

      should "create a new step with status 'in progress' when pairing parameters are provided" do
        skip 'not supported'
        rule = '{?p :is :Tube . ?q :is :Tube2.} => { :step :addFacts { ?p :transfer ?q.}.}.'
        SupportN3.parse_string(rule, {}, @step_type)
        assets = []
        10.times.each do |i|
          asset = FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Tube')
          ]
          asset.generate_barcode(i)
          asset2 = FactoryGirl.create :asset, facts: [
            FactoryGirl.create(:fact, predicate: 'is', object: 'Tube2')
          ]
          asset2.generate_barcode(10 + i)
          assets << asset
          assets << asset2
        end

        @asset_group.assets = assets
        barcodes_pairs = assets.map(&:barcode).each_slice(2).to_a

        pairings = []

        @step_type.reload

        cgp = @step_type.condition_groups.first
        cgq = @step_type.condition_groups.last
        barcodes_pairs.each_with_index do |pair, _index|
          pairings.push(cgp.id => pair[0],
                        cgq.id => pair[1])
        end

        c = Step.all.count

        post :create, { activity_id: @activity.id, step_type_id: @step_type.id,
                        step: {
                          data_params: { pairings: pairings }.to_json,
                          data_action: 'linking',
                          data_action_type: 'progress_step',
                          state: 'in_progress'
                        } }, session: { token: @user.token }
        assert_equal 10, assets.map { |a| a.facts.with_predicate('transfer') }.flatten.uniq.count
        assert_equal Step.all.count, c + 1
        assert_equal true, Step.last.in_progress?
        post :create, activity_id: @activity.id, step_type_id: @step_type.id,
                      step: {
                        state: 'in_progress',
                        data_params: '{}',
                        data_action: 'linking',
                        data_action_type: 'progress_step'
                      }
        assert_equal Step.all.count, c + 1
        assert_equal false, Step.last.in_progress?
        assert_equal 10, assets.map { |a| a.facts.with_predicate('transfer') }.flatten.uniq.count
      end
    end
  end
end
