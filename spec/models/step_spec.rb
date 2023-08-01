require 'rails_helper'

def assert_equal(a, b)
  expect(a).to eq(b)
end

def cwm_engine?
  Rails.configuration.inference_engine == :cwm
end

RSpec.describe Step, type: :model do
  let(:activity) { create :activity }
  let(:user) { create :user, username: 'test' }
  before { Delayed::Worker.delay_jobs = false }

  def build_instance
    create_step
  end

  def create_step
    step =
      FactoryBot.create(:step, { activity: activity, step_type: @step_type, asset_group: @asset_group, user: user })
    step.run!
    step
  end

  def run_step_type(step_type, asset_group)
    step = create(:step, { activity: activity, step_type: step_type, asset_group: asset_group, user: user })
    step.run!
    step
  end

  def create_asset(type)
    create(:asset, facts: [create(:fact, predicate: 'a', object: type)])
  end

  def create_action_for_creating_asset(asset_type)
    cg3 = create(:condition_group, name: 'my_new_asset')
    create(:action, action_type: 'createAsset', predicate: 'a', subject_condition_group: cg3, object: asset_type)
  end

  def create_action_for_connecting_condition_groups(predicate, cg1, cg2)
    create(
      :action,
      action_type: 'addFacts',
      predicate: predicate,
      subject_condition_group: cg1,
      object_condition_group: cg2
    )
  end

  def create_condition_to_select_asset_type(asset_type)
    create(:condition, predicate: 'a', object: asset_type)
  end

  def create_condition_group_to_select_asset_type(asset_type, name = nil)
    create(:condition_group, name: name, conditions: [create_condition_to_select_asset_type(asset_type)])
  end

  def create_assets(num, type)
    Array.new(num) { create_asset(type) }
  end

  describe '#create' do
    context 'when creating a step with a specific printer config' do
      let(:printer_data_config) { { 'Tube' => '1234', 'Plate' => '6789' } }
      it 'stores the printer config in the database' do
        s = create(:step, printer_config: printer_data_config)
        s2 = Step.find_by(id: s.id)
        expect(s2.printer_config).to eq(printer_data_config)
      end
    end
  end

  describe '#run' do
    setup do
      @step_type = FactoryBot.create :step_type

      @cg1 = FactoryBot.create(:condition_group, { name: 'p' })
      @cg1.conditions << FactoryBot.create(:condition, { predicate: 'is', object: 'Tube' })
      @cg2 = FactoryBot.create(:condition_group, { name: 'q' })
      @cg2.conditions << FactoryBot.create(:condition, { predicate: 'is', object: 'Rack' })
      @step_type.condition_groups << @cg1
      @step_type.condition_groups << @cg2
      @tubes =
        Array.new(7) do |_i|
          FactoryBot.create(
            :asset,
            {
              facts: [
                FactoryBot.create(:fact, predicate: 'is', object: 'Tube'),
                FactoryBot.create(:fact, predicate: 'is', object: 'Full')
              ]
            }
          )
        end
      @racks =
        Array.new(5) do |_i|
          FactoryBot.create(
            :asset,
            {
              facts: [
                FactoryBot.create(:fact, predicate: 'is', object: 'Rack'),
                FactoryBot.create(:fact, predicate: 'is', object: 'Full')
              ]
            }
          )
        end
      @assets = [@tubes, @racks].flatten
      @asset_group = FactoryBot.create(:asset_group, { assets: @assets })
    end

    describe 'when creating a new step' do
      it 'raises an exception if assets are not compatible with step_type' do
        @cg1.update(cardinality: 1)
        expect { @step = create_step }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe 'with related assets in conditions' do
      setup do
        @cg2.conditions << FactoryBot.create(:condition, { predicate: 'contains', object_condition_group_id: @cg1.id })

        @action =
          FactoryBot.create(
            :action,
            { action_type: 'addFacts', predicate: 'is', object: 'TubeRack', subject_condition_group: @cg2 }
          )
        @step_type.actions << @action

        @racks.each_with_index do |r, i|
          r.facts << FactoryBot.create(:fact, predicate: 'contains', object_asset_id: @tubes[i].id)
        end
      end

      it 'executes the step when the related condition is met' do
        previous_num = @asset_group.assets.count
        @step = create_step

        @racks.each(&:reload)

        @racks.each { |rack| assert_equal true, rack.has_fact?(@action) }
        expect(Operation.all.count).to eq(@racks.count)
      end

      describe 'with wildcards' do
        setup do
          @wildcard = FactoryBot.create :condition_group
          condition = FactoryBot.create :condition, { predicate: 'position', object_condition_group: @wildcard }
          @cg2.conditions << condition
        end

        describe 'when the conditions is not met' do
          it 'does not execute the rule when the wildcard condition is not met' do
            previous_num = @asset_group.assets.count

            expect { @step = create_step }.to raise_error(StandardError)

            @racks.each(&:reload)

            @racks.each { |rack| assert_equal false, rack.has_fact?(@action) }
            expect(Operation.all.count).to eq(0)
          end
        end

        describe 'when the wildcard conditions are met' do
          setup do
            @racks.each_with_index do |rack, idx|
              rack.facts << FactoryBot.create(:fact, { predicate: 'position', object: idx.to_s })
            end
          end

          it 'executes wildcard condition groups' do
            previous_num = @asset_group.assets.count

            @step = create_step

            @racks.each(&:reload)

            @racks.each { |rack| assert_equal true, rack.has_fact?(@action) }
            expect(Operation.all.count).to eq(@racks.count)
          end

          it 'uses the value of the condition group evaluated for the same cg' do
            previous_num = @asset_group.assets.count

            @action =
              FactoryBot.create(
                :action,
                {
                  action_type: 'addFacts',
                  predicate: 'value',
                  object_condition_group: @wildcard,
                  subject_condition_group: @cg2
                }
              )
            @step_type.actions << @action

            @step = create_step

            @racks.each(&:reload)

            @racks.each_with_index { |rack, pos| assert_equal true, rack.has_literal?('value', pos.to_s) }
            expect(Operation.all.count).to eq(2 * @racks.count)
          end

          it 'uses the value of the condition group to relate different groups' do
            # ?x :t ?pos . ?y :v ?pos . => ?x :relates ?y .

            previous_num = @asset_group.assets.count
            @cg1.conditions <<
              FactoryBot.create(:condition, { predicate: 'location', object_condition_group: @wildcard })
            @cg2.conditions <<
              FactoryBot.create(:condition, { predicate: 'location', object_condition_group: @wildcard })
            @action =
              FactoryBot.create(
                :action,
                {
                  action_type: 'addFacts',
                  predicate: 'relates',
                  object_condition_group: @cg1,
                  subject_condition_group: @cg2
                }
              )
            @step_type.actions << @action

            @tubes.each_with_index do |tube, idx|
              tube.facts << FactoryBot.create(:fact, { predicate: 'location', object: idx.to_s })
            end

            @racks.each_with_index do |rack, idx|
              rack.facts << FactoryBot.create(:fact, { predicate: 'location', object: idx.to_s })
            end

            @step = create_step

            @racks.each(&:reload)
            @tubes.each(&:reload)

            @tubes.each_with_index { |tube, _pos| assert_equal true, tube.facts.with_predicate('relates').count == 0 }
            @racks.each_with_index { |rack, _pos| assert_equal true, rack.facts.with_predicate('relates').count != 0 }
            @racks
              .zip(@tubes)
              .each do |list|
                rack, tube = list[0], list[1]
                assert_equal tube, rack.facts.with_predicate('relates').first.object_asset
              end
          end
        end
      end
    end

    describe 'with createAsset action type' do
      setup do
        @cg3 = FactoryBot.create(:condition_group, { name: 'r' })
        @cg3.conditions << FactoryBot.create(:condition, { predicate: 'is', object: 'NewTube' })
        @action =
          FactoryBot.create(
            :action,
            { action_type: 'createAsset', predicate: 'is', object: 'NewTube', subject_condition_group: @cg3 }
          )
        if cwm_engine?
          @action2 =
            FactoryBot.create(
              :action,
              {
                action_type: 'createAsset',
                predicate: 'createdBy',
                object_condition_group: @cg1,
                subject_condition_group: @cg3
              }
            )
          @action3 =
            FactoryBot.create(
              :action,
              {
                action_type: 'createAsset',
                predicate: 'createdBy',
                object_condition_group: @cg2,
                subject_condition_group: @cg3
              }
            )

          @step_type.actions << [@action, @action2, @action3]
        else
          @step_type.actions << @action
        end
      end

      it 'creates an asset for each input and adds it to the asset group' do
        previous_num = @asset_group.assets.count
        @step = create_step

        @asset_group.reload
        assets_created = Asset.with_fact('is', 'NewTube')
        expect(previous_num).not_to eq(@asset_group.assets.count)

        # expect(assets_created.length).to eq(previous_num)
        if cwm_engine?
          expect(assets_created.length).to eq(@tubes.count * @racks.count)
          expect(Operation.all.count).to eq(assets_created.count * 3)
        else
          expect(assets_created.length).to eq(previous_num)
          expect(Operation.all.count { |o| o.action_type == 'createAssets' }).to eq(assets_created.count)
        end
        expect(assets_created.length + previous_num).to eq(@asset_group.assets.count)
      end

      unless cwm_engine?
        it 'cardinality restricts the number of assets created when it is below the number of inputs' do
          previous_num = @asset_group.assets.count
          @cg3.update(cardinality: 6)
          @step = create_step

          @asset_group.reload
          assets_created = Asset.with_fact('is', 'NewTube')
          expect(previous_num).not_to eq(@asset_group.assets.count)
          expect(assets_created.length).to eq(6)
          expect(assets_created.length + previous_num).to eq(@asset_group.assets.count)

          expect(Operation.all.count { |o| o.action_type == 'createAssets' }).to eq(assets_created.count)
        end

        it 'cardinality does not restrict the number of assets created when it is over the number of inputs' do
          previous_num = @asset_group.assets.count
          cardinality = @tubes.length + @racks.length + 2
          @cg3.update(cardinality: cardinality)
          @step = create_step

          @asset_group.reload
          assets_created = Asset.with_fact('is', 'NewTube')
          expect(previous_num).not_to eq(@asset_group.assets.count)
          expect(assets_created.length).to eq(cardinality)

          # expect(assets_created.length+previous_num).to eq(@asset_group.assets.count)

          expect(Operation.all.count { |o| o.action_type == 'createAssets' }).to eq(assets_created.count)
        end
      end

      it 'adds facts to all the assets created' do
        previous_num = @asset_group.assets.count
        action =
          FactoryBot.create(
            :action,
            { action_type: 'createAsset', predicate: 'has', object: 'MoreData', subject_condition_group: @cg3 }
          )
        @step_type.actions << action

        @step = create_step
        @asset_group.reload
        assets_created = Asset.with_fact('has', 'MoreData')
        assets2_created = Asset.with_fact('is', 'NewTube')
        expect(assets_created - assets2_created).to eq([])
        expect(assets2_created - assets_created).to eq([])
        expect(previous_num).not_to eq(@asset_group.assets.count)
        if cwm_engine?
          expect(assets_created.length).to eq(@tubes.count * @racks.count)
          expect(Operation.all.count).to eq(4 * assets_created.count)
        else
          expect(assets_created.length).to eq(previous_num)
        end
        expect(assets_created.length + previous_num).to eq(@asset_group.assets.count)
      end

      it 'is able to execute addFacts and createFacts referring to the same condition group' do
        previous_num = @asset_group.assets.count
        action =
          FactoryBot.create(
            :action,
            { action_type: 'addFacts', predicate: 'has', object: 'MoreData', subject_condition_group: @cg3 }
          )
        @step_type.actions << action
        @step = create_step
        expect(@asset_group.assets.count).to eq(previous_num * 2)
        expect(Operation.all.count { |o| o.action_type == 'addFacts' }).to eq(2 * previous_num)
      end

      describe 'with overlapping assets' do
        setup do
          @tubes_and_racks =
            Array.new(7) do
              FactoryBot.create(
                :asset,
                {
                  facts: [
                    FactoryBot.create(:fact, predicate: 'is', object: 'Rack'),
                    FactoryBot.create(:fact, predicate: 'is', object: 'Tube')
                  ]
                }
              )
            end
          @asset_group.assets << @tubes_and_racks
        end

        it 'creates assets also for the overlapped assets' do
          previous_num = @asset_group.assets.count
          @step = create_step

          @asset_group.reload
          assets_created = Asset.with_fact('is', 'NewTube')
          expect(previous_num).not_to eq(@asset_group.assets.count)
          if cwm_engine?
            total_count = (@tubes_and_racks.count + @tubes.count) * (@tubes_and_racks.count + @racks.count)
            expect(assets_created.length).to eq(total_count)

            # Its 3 actions for each asset created, but the 'createdBy' relations with the
            # asset themselves wont happen twice (this is the case only for the @tubes_and_racks
            # overlapped assets), so its 7
            total_operations = (assets_created.count * 3) - @tubes_and_racks.count
            expect(Operation.all.count).to eq(total_operations)
          else
            expect(assets_created.length).to eq(previous_num)
          end
          expect(assets_created.length + previous_num).to eq(@asset_group.assets.count)
        end
      end
    end

    describe 'with unselectAsset action type' do
      setup do
        @action =
          FactoryBot.create(
            :action,
            { action_type: 'addFacts', predicate: 'is', object: 'Empty', subject_condition_group: @cg1 }
          )
        @step_type.actions << @action
      end

      it 'unselects elements from condition group' do
        @cg1.update(keep_selected: false)

        @asset_group.assets.reload
        assert_equal true, @tubes.all? { |tube| @asset_group.assets.include?(tube) }

        @step = create_step
        @asset_group.reload
        @asset_group.assets.reload
        @asset_group.assets.each(&:reload)

        assert_equal false, @tubes.any? { |tube| @asset_group.assets.include?(tube) }

        # expect(Operation.all.count).to eq(@tubes.length)
      end

      describe 'with overlapping assets' do
        setup do
          @tubes_and_racks =
            Array.new(7) do
              FactoryBot.create(
                :asset,
                {
                  facts: [
                    FactoryBot.create(:fact, predicate: 'is', object: 'Rack'),
                    FactoryBot.create(:fact, predicate: 'is', object: 'Tube')
                  ]
                }
              )
            end
          @asset_group.assets << @tubes_and_racks
        end

        it 'unselects the overlapped assets' do
          @cg1.update(keep_selected: false)

          @asset_group.assets.reload
          assert_equal true, [@tubes, @tubes_and_racks].flatten.all? { |tube| @asset_group.assets.include?(tube) }

          @step = create_step

          @asset_group.reload
          @asset_group.assets.reload
          @asset_group.assets.each(&:reload)

          assert_equal false, [@tubes, @tubes_and_racks].flatten.all? { |tube| @asset_group.assets.include?(tube) }
        end
      end
    end

    describe 'when using different values of connect_by' do
      let(:asset_group) { create(:asset_group, assets: [origins, targets].flatten) }

      shared_examples 'a step type that can connect by position' do
        let(:step_type) do
          create(:step_type, condition_groups: condition_groups, actions: actions, connect_by: 'position')
        end
        it 'connects origins with destinations 1 to 1 leaving outside assets without associated pair' do
          s = run_step_type(step_type, asset_group)
          origins.each(&:reload)

          transfers = Fact.where(predicate: 'transfer')
          expect(transfers.compact.count).to eq([origins.count, num_destinations].min)
          expect(transfers.map(&:asset).uniq.count).to eq([origins.count, num_destinations].min)
          expect(transfers.map(&:object_asset).uniq.count).to eq([origins.count, num_destinations].min)
        end
      end

      shared_examples 'a step type that can connect N to N' do
        let(:step_type) { create(:step_type, condition_groups: condition_groups, actions: actions, connect_by: nil) }

        it 'connects all origins with all destinations' do
          s = run_step_type(step_type, asset_group)
          origins.each(&:reload)
          destinations.each(&:reload)
          transfers =
            origins
              .map(&:facts)
              .map { |facts| facts.with_predicate('transfer') }
              .flatten
              .sort do |a, b|
                (a.asset.id == b.asset.id) ? (a.object_asset.id <=> b.object_asset.id) : (a.asset.id <=> b.asset.id)
              end
          expect(transfers.compact.count).to eq(origins.count * num_destinations)
          expect(transfers.map(&:asset).uniq.count).to eq(origins.count)
          expect(transfers.map(&:object_asset).uniq.count).to eq(num_destinations)
        end
      end

      context 'when the destinations exist upfront' do
        let(:condition_groups) do
          [create_condition_group_to_select_asset_type('Tube'), create_condition_group_to_select_asset_type('Rack')]
        end
        let(:actions) do
          [create_action_for_connecting_condition_groups('transfer', condition_groups.first, condition_groups.last)]
        end
        let(:targets) { destinations }
        context 'when there are more destinations than origins' do
          let(:origins) { create_assets(5, 'Tube') }
          let(:destinations) { create_assets(num_destinations, 'Rack') }
          let(:num_destinations) { 7 }
          it_should_behave_like 'a step type that can connect by position'
          it_should_behave_like 'a step type that can connect N to N'
        end

        context 'when there are more origins than destinations' do
          let(:origins) { create_assets(7, 'Tube') }
          let(:destinations) { create_assets(num_destinations, 'Rack') }
          let(:num_destinations) { 5 }
          it_should_behave_like 'a step type that can connect by position'
          it_should_behave_like 'a step type that can connect N to N'
        end

        context 'when there are equal number of origins and destinations' do
          let(:origins) { create_assets(7, 'Tube') }
          let(:destinations) { create_assets(num_destinations, 'Rack') }
          let(:num_destinations) { 7 }
          it_should_behave_like 'a step type that can connect by position'
          it_should_behave_like 'a step type that can connect N to N'
        end
      end

      context 'when the destinations are going to be created during the execution' do
        let(:condition_groups) { [create_condition_group_to_select_asset_type('Tube')] }
        let(:action_for_creating_rack) { create_action_for_creating_asset('Rack') }
        let(:actions) do
          [
            create_action_for_connecting_condition_groups(
              'transfer',
              condition_groups.first,
              action_for_creating_rack.subject_condition_group
            ),
            action_for_creating_rack
          ]
        end
        let(:origins) { create_assets(5, 'Tube') }
        let(:targets) { [] }

        let(:destinations) { [] }
        let(:num_destinations) { 5 }

        it_should_behave_like 'a step type that can connect by position'
        it_should_behave_like 'a step type that can connect N to N'
      end
    end

    describe 'with addFacts action_type' do
      describe 'with one action' do
        setup do
          @action =
            FactoryBot.create(
              :action,
              { action_type: 'addFacts', predicate: 'is', object: 'Empty', subject_condition_group: @cg1 }
            )
          @step_type.actions << @action
        end

        it 'adds the fact to the matched assets' do
          @asset_group.assets.reload
          @step = create_step
          @tubes.each(&:reload)
          @tubes.each { |asset| assert_equal true, asset.has_fact?(@action) }
          @racks.each(&:reload)
          @racks.each { |asset| assert_equal false, asset.has_fact?(@action) }
          expect(Operation.all.count).to eq(@tubes.length)
        end

        describe 'relating different condition groups' do
          setup do
            @action.update(subject_condition_group: @cg1)
            @action.update(object_condition_group: @cg2)
          end

          it 'connects 1 to N if cardinality is set to 1 in the subject condition group' do
            @asset_group.update(assets: [@tubes.first, @racks].flatten)
            @cg1.update(cardinality: 1)

            @step = create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @racks.each do |rack|
              assert_equal true,
                           @tubes.first.has_fact?(build(:fact, predicate: @action.predicate, object_asset_id: rack.id))
            end

            assert_equal false,
                         @tubes.last.has_fact?(
                           build(:fact, predicate: @action.predicate, object_asset_id: @racks.first.id)
                         )
            expect(Operation.all.count).to eq(@racks.length)
          end

          it 'connects N to 1 if cardinality is set to 1 in the object condition group' do
            @asset_group.update(assets: [@tubes, @racks.first].flatten)
            @cg2.update(cardinality: 1)

            @step = create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each do |tube|
              assert_equal true,
                           tube.has_fact?(build(:fact, predicate: @action.predicate, object_asset_id: @racks.first.id))
            end
            assert_equal false,
                         @tubes.first.has_fact?(
                           build(:fact, predicate: @action.predicate, object_asset_id: @racks.last.id)
                         )
            expect(Operation.all.count).to eq(@tubes.length)
          end

          it 'connects 1 to 1 if cardinality is set to 1 in both subject and object condition groups' do
            @asset_group.update(assets: [@tubes.first, @racks.first].flatten)
            @cg1.update(cardinality: 1)
            @cg2.update(cardinality: 1)

            @step = create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            assert_equal true,
                         @tubes.first.has_fact?(
                           build(:fact, predicate: @action.predicate, object_asset_id: @racks.first.id)
                         )
            expect(Operation.all.count).to eq(1)
          end

          it 'connects N to N if no cardinality is set' do
            @asset_group.update(assets: [@tubes, @racks].flatten)

            @step = create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each do |tube|
              @racks.each do |rack|
                assert_equal true, tube.has_fact?(build(:fact, predicate: @action.predicate, object_asset_id: rack.id))
              end
            end
            expect(Operation.all.count).to eq(@racks.length * @tubes.length)
          end

          describe 'with overlapping assets' do
            setup do
              @tubes_and_racks =
                Array.new(7) do
                  FactoryBot.create(
                    :asset,
                    {
                      facts: [
                        FactoryBot.create(:fact, predicate: 'is', object: 'Rack'),
                        FactoryBot.create(:fact, predicate: 'is', object: 'Tube')
                      ]
                    }
                  )
                end
              @asset_group.assets << @tubes_and_racks
            end

            it 'connects overlapped assets with themselves as consequence of the condition', last: true do
              @asset_group.assets.reload

              @step = create_step

              @tubes.each(&:reload)
              @racks.each(&:reload)
              @tubes_and_racks.each(&:reload)

              [@tubes, @tubes_and_racks].flatten.each do |tube|
                [@racks, @tubes_and_racks].flatten.each do |rack|
                  assert_equal true,
                               tube.has_fact?(build(:fact, predicate: @action.predicate, object_asset_id: rack.id))
                end
              end
              expect(Operation.all.count).to eq(
                (@racks.length + @tubes_and_racks.length) * (@tubes.length + @tubes_and_racks.length)
              )
            end
          end
        end
      end

      describe 'with several actions' do
        setup do
          @action = FactoryBot.create(:action, { action_type: 'addFacts', predicate: 'is', object: 'Empty' })
          @action2 = FactoryBot.create(:action, { action_type: 'addFacts', predicate: 'is', object: 'Red' })

          @step_type.actions << @action
          @step_type.actions << @action2
        end

        describe 'for the same condition group' do
          setup do
            @action.update(subject_condition_group: @cg1)
            @action2.update(subject_condition_group: @cg1)
          end
          it 'adds all the facts to all the assets of the condition group' do
            create_step
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end

            expect(Operation.all.count).to eq(2 * @tubes.length)
          end
        end

        describe 'for different condition groups' do
          setup do
            @action.update(subject_condition_group: @cg1)
            @action2.update(subject_condition_group: @cg2)
          end

          it 'adds the specific facts to the assets of the specific condition group' do
            create_step
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            expect(Operation.all.count).to eq(@racks.length + @tubes.length)
          end
        end
      end
    end

    describe 'with removeFacts action_type' do
      describe 'with one action' do
        setup do
          @action =
            FactoryBot.create(
              :action,
              { action_type: 'removeFacts', predicate: 'is', object: 'Tube', subject_condition_group: @cg1 }
            )
          @step_type.actions << @action
        end

        it 'removes the fact from the matched assets', last: true do
          @asset_group.assets.reload
          @tubes.each { |asset| assert_equal true, asset.has_fact?(@action) }
          @step = create_step
          @tubes.each(&:reload)
          @tubes.each { |asset| assert_equal false, asset.has_fact?(@action) }
          @racks.each(&:reload)
          @racks.each { |asset| assert_equal false, asset.has_fact?(@action) }
          expect(Operation.all.count).to eq(@tubes.length)
        end
      end
      describe 'relating different condition groups' do
        setup do
          # Something like removeFact(?tube :relatesTo ?rack)
          @action =
            FactoryBot.create(
              :action,
              {
                action_type: 'removeFacts',
                predicate: 'relatesTo',
                subject_condition_group: @cg1,
                object_condition_group: @cg2
              }
            )
          @step_type.actions << @action
        end

        it 'removes the link between both assets' do
          @tubes.first.facts <<
            FactoryBot.create(
              :fact,
              { predicate: 'relatesTo', object: @racks.first.relation_id, object_asset: @racks.first, literal: false }
            )

          assert_equal 1, @tubes.first.facts.count { |f| f.predicate == 'relatesTo' }

          @asset_group.update(assets: [@tubes.first, @racks.first].flatten)
          create_step

          @tubes.each(&:reload)
          @racks.each(&:reload)
          assert_equal 0, @tubes.first.facts.count { |f| f.predicate == 'relatesTo' }
          expect(Operation.all.count).to eq(1)
        end
        describe 'relating several assets' do
          it 'removes the link between all assets', last: true do
            @tubes.each do |tube|
              @racks.each do |rack|
                tube.facts <<
                  FactoryBot.create(
                    :fact,
                    { predicate: 'relatesTo', object: rack.relation_id, object_asset: rack, literal: false }
                  )
              end
            end

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each { |tube| assert_equal true, (tube.facts.count { |f| f.predicate == 'relatesTo' } > 0) }

            create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each { |tube| assert_equal 0, tube.facts.count { |f| f.predicate == 'relatesTo' } }
            expect(Operation.all.count).to eq(@racks.length * @tubes.length)
          end

          it 'removes the link just between the matched assets', last: true do
            @tubes.each do |tube|
              tube.facts <<
                FactoryBot.create(
                  :fact,
                  {
                    predicate: 'relatesTo',
                    object: @tubes.first.relation_id,
                    object_asset: @racks.first,
                    literal: false
                  }
                )
            end

            @racks.each do |rack|
              rack.facts <<
                FactoryBot.create(
                  :fact,
                  {
                    predicate: 'relatesTo',
                    object: @racks.first.relation_id,
                    object_asset: @racks.first,
                    literal: false
                  }
                )
            end

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each { |tube| assert_equal true, tube.facts.any? { |f| f.predicate == 'relatesTo' } }

            @racks.each { |rack| assert_equal true, rack.facts.any? { |f| f.predicate == 'relatesTo' } }

            create_step

            @tubes.each(&:reload)
            @racks.each(&:reload)

            @tubes.each { |tube| assert_equal 0, tube.facts.count { |f| f.predicate == 'relatesTo' } }

            @racks.each { |rack| assert_equal 1, rack.facts.count { |f| f.predicate == 'relatesTo' } }

            expect(Operation.all.count).to eq(@tubes.length)
          end
        end
      end
      describe 'with several actions' do
        setup do
          @action = FactoryBot.create(:action, { action_type: 'removeFacts', predicate: 'is', object: 'Tube' })
          @action2 = FactoryBot.create(:action, { action_type: 'removeFacts', predicate: 'is', object: 'Full' })

          @step_type.actions << @action
          @step_type.actions << @action2
        end

        describe 'for the same condition group' do
          setup do
            @action.update(subject_condition_group: @cg1)
            @action2.update(subject_condition_group: @cg1)
          end
          it 'removes all the facts to all the assets of the condition group' do
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end

            create_step
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            expect(Operation.all.count).to eq(2 * @tubes.length)
          end
        end

        describe 'for different condition groups' do
          setup do
            @action.update(subject_condition_group: @cg1)
            @action2.update(subject_condition_group: @cg2)
          end

          it 'removes the specific facts to the assets of the specific condition group' do
            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal true, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end

            create_step

            @tubes.each(&:reload)
            @tubes.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal true, asset.has_fact?(@action2)
            end
            @racks.each(&:reload)
            @racks.each do |asset|
              assert_equal false, asset.has_fact?(@action)
              assert_equal false, asset.has_fact?(@action2)
            end
            expect(Operation.all.count).to eq(@tubes.length + @racks.length)
          end
        end
      end
    end
  end
end
