# frozen_string_literal: true
class RerackingController < ApplicationController
  include ActionController::Live

  before_action :set_instrument
  before_action :set_activity_type

  before_action :set_activity, only: [:update, :show]

  def set_activity_type
    @activity_type = ActivityType.find_by_name('Re-Racking')
  end

  def set_activity
    @activity = Activity.find_by_id(params[:id])
    @asset_group = @activity.asset_group
    @assets = @asset_group.assets
    @assets_grouped = []
  end

  def set_instrument
    @instrument = Instrument.first
    @kit = Kit.first
  end

  def index
    @activity = Reracking.new
  end

  def update; end

  def show
    @assets = @activity.asset_group.assets
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html { render :update }
    end
  end

  def create
    @asset_group = AssetGroup.create
    @assets = @asset_group.assets

    @activity = Activity.new(
      activity_type: @activity_type,
      asset_group: @asset_group,
      instrument: @instrument,
      kit: @kit
    )
    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def steps_finished
    @in_steps_finished = true
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html do
        render 'steps/_finished', locals: {
          steps: @steps,
          activity: @activity
        }, layout: false
      end
    end
  end
end
