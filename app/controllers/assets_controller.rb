require 'pry'
class AssetsController < ApplicationController
  before_action :prepare_asset_params, only: [:create, :update]
  before_action :set_asset, only: [:show, :edit, :update, :destroy]
  before_action :set_queries, only: [:search]

  # GET /assets
  # GET /assets.json
  def index
    @assets = Asset.all.includes(:facts).paginate(:page => params[:page], :per_page => 5)
  end

  def search
    @assets = Asset.assets_for_queries(@queries)
    @activities = @assets.map(&:activities)
    @steps = Step.for_assets(@assets)

    # For printing
    @asset_group = AssetGroup.create!
    @asset_group.add_assets(@assets)

    respond_to do |format|
      format.html { render :search, layout: false }
    end
  end

  # GET /assets/1
  # GET /assets/1.json
  def show_by_internal_id
    @asset = Asset.find!(params[:id])
    redirect_to asset_path(@asset.uuid, :format => nil)
  end

  # GET /assets/1
  # GET /assets/1.json
  def show
    #@asset = Asset.find_by_uuid!(params[:uuid])
    respond_to do |format|
      format.html { render :show }
      format.n3 { render :show }
    end    
  end


  # GET /assets/new
  def new
    @asset = Asset.new
  end

  # GET /assets/1/edit
  def edit
  end

  # POST /assets
  # POST /assets.json
  def create
    @asset = Asset.new(@prepared_params)

    respond_to do |format|
      if @asset.save
        format.html { redirect_to @asset, notice: 'Asset was successfully created.' }
        format.json { render :show, status: :created, location: @asset }
      else
        format.html { render :new }
        format.json { render json: @asset.errors, status: :unActivityable_entity }
      end
    end
  end

  # PATCH/PUT /assets/1
  # PATCH/PUT /assets/1.json
  def update
    respond_to do |format|

      if @asset.update(@prepared_params)
        @asset.touch
        
        format.html { redirect_to @asset, notice: 'Asset was successfully updated.' }
        format.json { render :show, status: :ok, location: @asset }
      else
        format.html { render :edit }
        format.json { render json: @asset.errors, status: :unActivityable_entity }
      end
    end
  end

  # DELETE /assets/1
  # DELETE /assets/1.json
  def destroy
    @asset.destroy
    respond_to do |format|
      format.html { redirect_to assets_url, notice: 'Asset was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

    def print
      respond_to do |format|
        format.html { redirect_to @asset, notice: 'Asset was printed.' }
      end
    end

  private


    # Use callbacks to share common setup or constraints between actions.
  def set_asset
    @asset = if UUID_REGEXP.match(params[:id])
               Asset.find_by(uuid: params[:id])
             else
               Asset.find(params[:id])
             end
  end

    def set_queries
      valid_indexes = params.keys.map{|k| k.match(/^[pq](\d*)$/)}.compact.map{|k| k[1]}
      @queries = valid_indexes.map do |val|
        OpenStruct.new({:predicate => params["p"+val], :object => params["o"+val]})
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def asset_params
      params.require(:asset).permit(:barcode, :facts)
    end

    UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    def prepare_asset_params
      @prepared_params = asset_params
      @prepared_params[:facts] = JSON.parse(@prepared_params[:facts]).map do |obj|
        if UUID_REGEXP.match(obj["object"].to_s)
          ref = Asset.find_by(:uuid => obj["object"])
          Fact.create(:predicate => obj["predicate"], :object_asset => ref)
        else
          Fact.create(:predicate => obj["predicate"], :object => obj["object"])
        end
      end
    end
end
