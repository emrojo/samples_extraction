# frozen_string_literal: true
require 'rails_helper'

RSpec.describe :cancellable, cancellable: true do
  setup do
    @asset_group = FactoryGirl.create :asset_group
    @activity_type = FactoryGirl.create :activity_type
    @activity = FactoryGirl.create :activity, activity_type: @activity_type, asset_group: @asset_group
    @steps = Array.new(10) do
      build_step(%({?p :maxCardinality "1".} => {:step :createAsset {?p :a :Tube .}.} .), %(), activity: @activity)
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
    expect(@steps.any?(&:cancelled?)).to eq(false)
    @steps[5].cancel
    @steps.each(&:reload)
    expect(@steps.select(&:cancelled?).count).to eq(5)
    expected_ids = [@steps[5].id, @steps[5].steps_newer_than_me.map(&:id)].flatten.sort
    expect(@steps.select(&:cancelled?).map(&:id).sort).to eq(expected_ids)
  end

  it 'redoes your step and all the steps older than it' do
    expect(@steps.any?(&:cancelled?)).to eq(false)
    @steps[5].cancel
    @steps.each(&:reload)
    expect(@steps.select(&:cancelled?).count).to eq(5)
    expected_ids = [@steps[5].id, @steps[5].steps_newer_than_me.map(&:id)].flatten.sort
    expect(@steps.select(&:cancelled?).map(&:id).sort).to eq(expected_ids)

    @steps[9].remake
    @steps.each(&:reload)
    expect(@steps.any?(&:cancelled?)).to eq(false)
  end

  it 'deprecates all cancelled steps on step creation' do
    expect(@steps.any?(&:cancelled?)).to eq(false)
    @steps[5].cancel
    @steps.each(&:reload)
    expect(@steps.select(&:cancelled?).count).to eq(5)
    expected_ids = [@steps[5].id, @steps[5].steps_newer_than_me.map(&:id)].flatten.sort
    expect(@steps.select(&:cancelled?).map(&:id).sort).to eq(expected_ids)

    build_step(%({?p :maxCardinality "1".} => {:step :createAsset {?p :a :Tube .}.} .), %(), activity: @activity)
    @activity.steps.each(&:reload)
    expect(@activity.steps.count).to eq(6)
  end
end
