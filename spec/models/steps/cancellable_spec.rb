require 'rails_helper'
require 'inferences_helper'

RSpec.describe :cancellable, cancellable: true do
  setup do
    @asset = create :asset
    @fact = create(:fact, predicate: 'a', object: 'Rack')
    @asset.facts << @fact

    @asset_group = FactoryBot.create :asset_group
    @asset_group.assets << @asset
    @activity_type = FactoryBot.create :activity_type
    @activity = FactoryBot.create :activity, activity_type: @activity_type, asset_group: @asset_group
    @steps =
      Array.new(10) do
        step =
          build_step(
            '{?p :a :Rack.} => {:step :addFacts {?p :a :TubeRack .}.} .',
            '',
            activity: @activity,
            asset_group: @asset_group
          )
        step.run!
        step
      end
  end

  context '#remake_me' do
    it 'remakes cancelled operations' do
      @steps[0].operations.first.update(cancelled?: true)
      @steps[0].remake_me
      @steps[0].operations.reload
      expect(@steps[0].operations.all?(&:cancelled?)).to eq(false)
    end
  end

  it 'cancels all the operations of the step when cancelling the step' do
    expect(@steps[0].operations.any?(&:cancelled?)).to eq(false)
    @steps[0].cancel
    @steps.each(&:reload)
    expect(@steps[0].operations.all?(&:cancelled?)).to eq(true)
  end

  it 'redoes all the operations of the step when redoing the step' do
    expect(@steps[0].operations.any?(&:cancelled?)).to eq(false)
    @steps[0].cancel
    @steps.each(&:reload)
    expect(@steps[0].operations.all?(&:cancelled?)).to eq(true)

    @steps[0].remake
    @steps.each(&:reload)
    expect(@steps[0].operations.all?(&:cancelled?)).to eq(false)
  end

  it 'cancels your step and all the steps newer than it' do
    expect(@steps.any? { |s| s.cancelled? }).to eq(false)
    @steps[5].cancel
    @steps.each(&:reload)
    expect(@steps.count { |s| s.cancelled? }).to eq(5)
    expected_ids = [@steps[5].id, @steps[5].steps_newer_than_me.map(&:id)].flatten.sort
    expect(@steps.select { |s| s.cancelled? }.map(&:id).sort).to eq(expected_ids)
  end

  it 'redoes your step and all the steps older than it' do
    expect(@steps.any? { |s| s.cancelled? }).to eq(false)
    @steps[5].cancel
    @steps.each(&:reload)
    expect(@steps.count { |s| s.cancelled? }).to eq(5)
    expected_ids = [@steps[5].id, @steps[5].steps_newer_than_me.map(&:id)].flatten.sort
    expect(@steps.select { |s| s.cancelled? }.map(&:id).sort).to eq(expected_ids)

    @steps[9].remake
    @steps.each(&:reload)
    expect(@steps.any? { |s| s.cancelled? }).to eq(false)
  end
end
