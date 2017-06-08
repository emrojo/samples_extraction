# frozen_string_literal: true
class ActivitiesController < ApplicationController
  include ActionController::Live

  before_action :set_activity, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]
  before_action :set_asset_group, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]
  before_action :set_assets, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]

  before_action :set_activity_type, only: [:create_without_kit]

  before_action :select_assets_grouped, only: [:show, :update, :step_types_active, :steps_finished, :steps_finished_with_operations]

  before_action :set_kit, only: [:create]
  before_action :set_instrument, only: [:create]

  before_action :set_user, only: [:update]

  before_action :set_uploaded_files, only: [:update]
  # before_action :set_params_for_step_in_progress, only: [:update]

  # before_filter :session_authenticate, only: [:update, :create]

  def session_authenticate
    raise ActionController::InvalidAuthenticityToken unless session[:session_id]
  end

  def real_time_updates
    @activity = Activity.find(params[:activity_id])
    @asset_group = @activity.asset_group
    @assets_changing = @asset_group.assets.currently_changing

    response.headers['Content-Type'] = 'text/event-stream'
    # sse.write(@asset_group.last_update, event: 'asset_group')
    # sse.write(@assets_changing.pluck(:uuid), event: 'asset')

    msg =  "event: asset_group\n" #
    msg += "data: #{@asset_group.last_update} \n\n"

    msg += "event: asset\n"
    msg += "data: #{@assets_changing.pluck(:uuid)} \n\n"

    response.stream.write msg
  ensure
    response.stream.close
    # sse.close
  end

  def update
    select_assets_grouped

    @activity.finish unless params[:finish].nil?
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def show
    @assets = @activity.asset_group.assets
    @step_types = @activity.step_types_for(@assets)
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def index
    @my_activities = @current_user ? Activity.for_user(@current_user).include_activity_type : []
  end

  def finished
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

  def finished_with_operations
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html do
        render 'steps/_finished', locals: {
          steps: @steps,
          activity: @activity,
          selected_step_id: params[:step_id]
        }, layout: false
      end
    end
  end

  def create_without_kit
    @asset_group = AssetGroup.create
    @activity = @activity_type.activities.create(
      instrument: nil,
      activity_type: @activity_type,
      asset_group: @asset_group,
      kit: nil
    )
    @asset_group.update_attributes(activity_owner: @activity)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @asset_group = AssetGroup.create
    @activity_type = @kit.kit_type.activity_type
    @activity = @activity_type.activities.create(
      instrument: @instrument,
      activity_type: @activity_type,
      asset_group: @asset_group,
      kit: @kit
    )

    @asset_group.update_attributes(activity_owner: @activity)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = @current_user
    if @user.nil?
      flash[:danger] = 'User not found'
      redirect_to :back
    end
  end

  def set_kit
    @kit = Kit.find_by_barcode!(params[:kit_barcode])
  rescue ActiveRecord::RecordNotFound => e
    flash[:danger] = 'Kit not found'
    redirect_to :back
  end

  def set_activity_type
    @activity_type = ActivityType.find_by_id(params[:activity_type_id])
  rescue ActiveRecord::RecordNotFound => e
    flash[:danger] = 'Activity Type not found'
    redirect_to :back
  end

  def set_instrument
    @instrument = Instrument.find_by_barcode!(params[:instrument_barcode])
    unless @instrument.compatible_with_kit?(@kit)
      flash[:danger] = "Instrument not compatible with kit type '#{@kit.kit_type.name}'"
      redirect_to :back
    end
  rescue RecordNotFound => e
    flash[:danger] = 'Instrument not found'
    redirect_back
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_activity
    @activity = Activity.find(params[:id])
  end

  def set_asset_group
    @asset_group = @activity.asset_group
  end

  def set_assets
    @assets = @asset_group.assets.includes(:facts)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def activity_params
    params.require(:activity).permit(:kit_barcode, :asset_barcode, :step_type, :instrument_barcode, :delete_barcode)
  end

  def select_assets_grouped
    @assets_grouped = @asset_group.assets_by_fact_group
  end

  def set_uploaded_files
    @upload_ids = []
    @upload_ids = JSON.parse(params[:upload_ids]) if params[:upload_ids]
  end
end
