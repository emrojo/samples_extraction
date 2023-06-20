class StepTypesController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_step_type, only: %i[show edit update destroy]

  # GET /step_types
  # GET /step_types.json
  def index
    @step_types = StepType.not_deprecated unless @activity
    respond_to do |format|
      format.html { render 'active', layout: false } if @activity
      format.html { render 'index' }
    end
  end

  # GET /step_types/1
  # GET /step_types/1.json
  def show
    respond_to do |format|
      format.html { render :show }
      format.n3 { render :show }
    end
  end

  # GET /step_types/new
  def new
    @step_type = StepType.new
  end

  # GET /step_types/1/edit
  def edit; end

  # POST /step_types
  # POST /step_types.json
  def create
    @step_type = StepType.new(empty_options_set_to_nil(step_type_params))

    respond_to do |format|
      if @step_type.save
        format.html { redirect_to @step_type, notice: 'Step type was successfully created.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :created, location: @step_type }
      else
        format.html { render :new }
        format.json { render json: @step_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /step_types/1
  # PATCH/PUT /step_types/1.json
  def update
    respond_to do |format|
      if @step_type.update(empty_options_set_to_nil(step_type_params))
        format.html { redirect_to @step_type, notice: 'Step type was successfully updated.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :ok, location: @step_type }
      else
        format.html { render :edit }
        format.json { render json: @step_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /step_types/1
  # DELETE /step_types/1.json
  def destroy
    @step_type.destroy
    respond_to do |format|
      format.html { redirect_to step_types_url, notice: 'Step type was successfully destroyed.' } # rubocop:todo Rails/I18nLocaleTexts
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_step_type
    @step_type = StepType.find(params[:id])
  end

  def empty_options_set_to_nil(params)
    params_copy = params.dup
    if params
      %i[step_template connect_by step_action].each do |key|
        params_copy[key] = nil if params[key] && params[key].empty?
      end
    end
    params_copy
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def step_type_params
    params
      .require(:step_type)
      .permit(:n3_definition, :name, :step_template, :connect_by, :for_reasoning, :step_action, :priority)
  end
end
