class AssetsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_asset, only: %i[show edit update destroy print]
  before_action :set_queries, only: %i[search print_search]

  # GET /assets
  # GET /assets.json
  def index
    @assets = Asset.all.includes(:facts).paginate(page: params[:page], per_page: 5)
  end

  def print
    @asset.print(@current_user.printer_config)

    respond_to do |format|
      format.html { redirect_to @asset, notice: 'Asset was printed.' } # rubocop:todo Rails/I18nLocaleTexts
    end
  end

  def print_search
    @start_time = Time.now
    @assets = get_search_results(@queries).paginate(page: params[:page], per_page: 10)

    temp_group = AssetGroup.new
    temp_group.assets << @assets
    temp_group.print(@current_user.printer_config)

    respond_to { |format| format.html { render :search, notice: 'Search was printed.' } }
  end

  def search
    @start_time = Time.now
    @assets = get_search_results(@queries).paginate(page: params[:page], per_page: 10)

    @valid_indexes = valid_indexes

    respond_to { |format| format.html { render :search } }
  end

  # GET /assets/1
  # GET /assets/1.json
  def show_by_internal_id
    @asset = Asset.find!(params[:id])
    redirect_to asset_path(@asset.uuid, format: nil)
  end

  # GET /assets/1
  # GET /assets/1.json
  def show
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
  def edit; end

  # POST /assets
  # POST /assets.json
  def create
    @asset = Asset.new(asset_params)

    respond_to do |format|
      if @asset.save
        format.html { redirect_to @asset, notice: 'Asset was successfully created.' } # rubocop:todo Rails/I18nLocaleTexts
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
      if @asset.update(asset_params)
        @asset.touch

        format.html { redirect_to @asset, notice: 'Asset was successfully updated.' } # rubocop:todo Rails/I18nLocaleTexts
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
      format.html { redirect_to assets_url, notice: 'Asset was successfully destroyed.' } # rubocop:todo Rails/I18nLocaleTexts
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_asset
    @asset = TokenUtil::UUID_REGEXP.match(params[:id]) ? Asset.find_by(uuid: params[:id]) : Asset.find(params[:id])
  end

  def get_search_results(queries)
    Asset.assets_for_queries(queries)
  end

  def valid_indexes
    params.keys.filter_map { |k| k.match(/^[pq](\d*)$/) }.pluck(1)
  end

  def set_queries
    @queries =
      valid_indexes.map do |val|
        OpenStruct.new({ predicate: params['p' + val], object: params['o' + val] }) # rubocop:todo Style/OpenStructUse
      end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def asset_params
    params.require(:asset).permit(:barcode)
  end
end
