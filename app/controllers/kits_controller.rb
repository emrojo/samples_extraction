class KitsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_kit, only: %i[show edit update destroy]
  before_action :set_kit_types, only: %i[new show edit update]

  # GET /kits
  # GET /kits.json
  def index
    @kits = Kit.all
  end

  # GET /kits/1
  # GET /kits/1.json
  def show; end

  # GET /kits/new
  def new
    @kit = Kit.new
  end

  # GET /kits/1/edit
  def edit; end

  # POST /kits
  # POST /kits.json
  def create
    @kit = Kit.new(kit_params)
    respond_to do |format|
      if @kit.save
        format.html { redirect_to @kit, notice: 'Kit was successfully created.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :created, location: @kit }
      else
        format.html { render :new }
        format.json { render json: @kit.errors, status: :unActivityable_entity }
      end
    end
  end

  # PATCH/PUT /kits/1
  # PATCH/PUT /kits/1.json
  def update
    respond_to do |format|
      if @kit.update(kit_params)
        format.html { redirect_to @kit, notice: 'Kit was successfully updated.' } # rubocop:todo Rails/I18nLocaleTexts
        format.json { render :show, status: :ok, location: @kit }
      else
        format.html { render :edit }
        format.json { render json: @kit.errors, status: :unActivityable_entity }
      end
    end
  end

  # DELETE /kits/1
  # DELETE /kits/1.json
  def destroy
    @kit.destroy
    respond_to do |format|
      format.html { redirect_to kits_url, notice: 'Kit was successfully destroyed.' } # rubocop:todo Rails/I18nLocaleTexts
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_kit
    @kit = Kit.find(params[:id])
  end

  def set_kit_types
    @kit_types = KitType.all
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def kit_params
    params.require(:kit).permit(:barcode, :max_num_reactions, :num_reactions_performed, :kit_type_id)
  end
end
