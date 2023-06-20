class ActivitiesController < ApplicationController # rubocop:todo Style/Documentation
  include ActionController::Live

  before_action :set_activity, only: %i[show update]
  before_action :set_instrument, only: [:create]
  before_action :set_kit, only: [:create]
  before_action :set_activity_type, only: [:create]
  before_action :set_user, only: [:update]

  # before_action :session_authenticate, only: [:update, :create]

  def session_authenticate
    raise ActionController::InvalidAuthenticityToken unless session[:session_id]
  end

  def index
    @my_activities = @current_user ? Activity.for_user(@current_user) : []
  end

  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  def create
    @activity = @activity_type.create_activity(instrument: @instrument, kit: @kit)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @activity.finish if activity_params[:state] == 'finish'

    respond_to do |format|
      format.html { render :show }
      format.json { render :show, status: :created, location: @activity }
    end
  end

  private

  def set_user
    @user = @current_user
    if @user.nil?
      flash[:danger] = 'User not found' # rubocop:todo Rails/I18nLocaleTexts
      redirect_to :back
    end
  end

  def set_kit
    return true if activity_params[:activity_type_id]

    @kit = Kit.find_by_barcode!(activity_params[:kit_barcode])
  rescue ActiveRecord::RecordNotFound => e
    flash[:danger] = 'Kit not found' # rubocop:todo Rails/I18nLocaleTexts
    redirect_back(fallback_location: use_instrument_path(@instrument))
  end

  def set_instrument
    return true if activity_params[:activity_type_id]

    @instrument = Instrument.find_by_barcode!(activity_params[:instrument_barcode])
  rescue ActiveRecord::RecordNotFound => e
    flash[:danger] = 'Instrument not found' # rubocop:todo Rails/I18nLocaleTexts
    redirect_back(fallback_location: instruments_path)
  end

  def set_activity_type
    if activity_params[:activity_type_id]
      begin
        @activity_type = ActivityType.find(activity_params[:activity_type_id])
      rescue ActiveRecord::RecordNotFound => e
        flash[:danger] = 'Activity type not found' # rubocop:todo Rails/I18nLocaleTexts
        redirect_back(fallback_location: instruments_path) and return
      end
    else
      unless @instrument.compatible_with_kit?(@kit)
        flash[:danger] = "Instrument not compatible with kit type '#{@kit.kit_type.name}'"
        redirect_back(fallback_location: use_instrument_path(@instrument))
      end
      @activity_type = @kit.kit_type.activity_type
    end
    @activity_type
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_activity
    @activity = Activity.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def activity_params
    params.require(:activity).permit(:activity_type_id, :kit_barcode, :instrument_barcode, :state)
  end
end
