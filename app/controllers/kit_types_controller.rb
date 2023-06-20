class KitTypesController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_kit_type, only: %i[show edit update destroy]
  before_action :set_activity_types, only: %i[new show edit update]

  # GET /kit_types
  # GET /kit_types.json
  def index
    @kit_types = KitType.all
  end

  # GET /kit_types/1
  # GET /kit_types/1.json
  def show; end

  # GET /kit_types/new
  def new
    @kit_type = KitType.new
  end

  # GET /kit_types/1/edit
  def edit; end

  # POST /kit_types
  # POST /kit_types.json
  def create
    @kit_type = KitType.new(kit_type_params)

    respond_to do |format|
      if @kit_type.save
        format.html { redirect_to @kit_type, notice: 'Kit type was successfully created.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :created, location: @kit_type }
      else
        format.html { render :new }
        format.json { render json: @kit_type.errors, status: :unActivityable_entity }
      end
    end
  end

  # PATCH/PUT /kit_types/1
  # PATCH/PUT /kit_types/1.json
  def update
    respond_to do |format|
      if @kit_type.update(kit_type_params)
        format.html { redirect_to @kit_type, notice: 'Kit type was successfully updated.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :ok, location: @kit_type }
      else
        format.html { render :edit }
        format.json { render json: @kit_type.errors, status: :unActivityable_entity }
      end
    end
  end

  # DELETE /kit_types/1
  # DELETE /kit_types/1.json
  def destroy
    @kit_type.destroy
    respond_to do |format|
      format.html { redirect_to kit_types_url, notice: 'Kit type was successfully destroyed.' } # rubocop:todo Rails/I18nLocaleTexts
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_kit_type
    @kit_type = KitType.find(params[:id])
  end

  def set_activity_types
    @activity_types = ActivityType.all
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def kit_type_params
    params.require(:kit_type).permit(:name, :target_type, :activity_type_id, :abbreviation)
  end
end
