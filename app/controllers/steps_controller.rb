require 'pry'

class StepsController < ApplicationController
  before_action :set_step, only: [:show, :edit, :update, :destroy]
  before_action :set_activity, only: [:create]
  before_action :set_printer_config, only: [:create]

  before_action :nested_steps, only: [:index]



  def nested_steps
    if step_params[:activity_id]
      @activity = Activity.find(step_params[:activity_id])
      @steps = @activity.steps
    else
      @steps = Step.all
    end
  end


  # GET /steps
  # GET /steps.json
  def index
    #redirect_to activities_path
    #return
    #@steps = Step.all
    respond_to do |format|
      format.json { render @steps }
      format.html { render 'finished', :layout => false } if @activity
    end
  end

  # GET /steps/1
  # GET /steps/1.json
  def show
  end

  # GET /steps/new
  def new
    @step = Step.new
  end

  # GET /steps/1/edit
  def edit
  end

  def params_for_printing
    params.require(:step).permit(:tube_printer_id, :plate_printer_id, 
      :state, :data_action, :data_action_type, :data_params)
  end

  def set_printer_config
    tube_printer = Printer.find_by(id: params_for_printing[:tube_printer_id]) || nil
    plate_printer = Printer.find_by(id: params_for_printing[:plate_printer_id]) ||  nil
    tube_rack_printer = Printer.find_by(id: params_for_printing[:plate_printer_id]) || nil
    @printer_config = {
      'Tube' => tube_printer.nil? ? "" : tube_printer.name,
      'Plate' => plate_printer.nil? ? "" : plate_printer.name,
      'TubeRack' => tube_rack_printer.nil? ? "" : tube_rack_printer.name
    }
  end

  # POST /activity/:activity_id/step_type/:step_type_id/create
  def create
    #begin
      valid_step_types = @activity.step_types_for(@assets)
      step_type_to_do = @activity.step_types.find_by_id!(@step_type.id)
      if valid_step_types.include?(step_type_to_do)
        @step = @activity.do_step(step_type_to_do, @current_user, create_step_params, @printer_config)
        session[:data_params] = {}        
      end
    #rescue Lab::Actions::InvalidDataParams => e
      # flash[:danger] = e.message
      # session[:data_params] = JSON.parse(create_step_params[:data_params]).merge({
      #   :error_params => e.error_params
      #   }).to_json
      # error_params = e.error_params
      # return
    #end
    respond_to do |format|
      if @step && @step.save
        #format.html { redirect_to @activity, notice: 'Step was successfully created.' }
        format.json { render :show, status: :created, location: @step }
      else
        if @step.nil?
          @step = Step.new
          #errors = error_params
        else
          errors = @step.errors
        end
        #format.html { render :new }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end



  # PATCH/PUT /steps/1
  # PATCH/PUT /steps/1.json
  def update
    #store_uploads

    respond_to do |format|
      if @step.update(create_step_params)
        format.html { redirect_to @step, notice: 'Step was successfully updated.' }
        format.json { render :show, status: :ok, location: @step }
      else
        format.html { render :edit }
        format.json { render json: @step.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /steps/1
  # DELETE /steps/1.json
  def destroy
    @step.destroy
    respond_to do |format|
      format.html { redirect_to steps_url, notice: 'Step was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_step
      @step = Step.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def step_params
      params.permit(:activity_id, :step_type_id, :id, :state)
    end

    def params_for_update
      params.require(:step).permit(:state)      
    end

    def create_step_params
      params.require(:step).permit(:state, :data_params,
        :data_action, :data_action_type, :file)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params[:activity_id])
      @asset_group = @activity.asset_group
      @assets = @asset_group.assets
      @step_type = StepType.find(params[:step_type_id])
    end



    def show_alert(data)
      @alerts = [] unless @alerts
      @alerts.push(data)
    end

end
