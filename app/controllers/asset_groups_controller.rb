class AssetGroupsController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_asset_group, only: %i[show update print upload]
  before_action :set_activity, only: %i[show update]
  before_action :update_barcodes, only: [:update]

  include ActionController::Live

  include ActivitiesHelper

  def show
    @assets = @asset_group.assets

    respond_to do |format|
      format.html { render @asset_group }
      format.n3 { render :show }
      format.json { head :ok }
    end
  end

  def update
    @assets = @asset_group.assets

    head :ok
  end

  def upload
    @file = UploadedFile.create(filename: params[:qqfilename], data: params[:qqfile].read)
    asset = @file.build_asset(content_type: params[:qqfile].content_type)
    @asset_group.update_with_assets([].concat(@asset_group.assets).push(asset))
    @asset_group.touch

    render json: { success: true }
  end

  def print
    summary = @asset_group.print(printer_config)

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, notice: summary.to_s }
      format.json { render json: { success: true, message: summary.to_s } }
    end
  rescue PrintMyBarcodeJob::PrintingError => e
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: e.message, status: e.status_code }
      format.json { render json: { success: false, message: e.message }, status: e.status_code }
    end
  end

  private

  def update_barcodes
    perform_assets_update

    render json: { errors: @alerts } if @alerts
  end

  def set_activity
    # I need the activity to be able to know the step_types compatible to show.
    @activity = Activity.find(params[:activity_id]) if params[:activity_id]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_asset_group
    @asset_group = AssetGroup.find(params[:id])
  end

  def perform_assets_update
    @asset_group.update(
      assets:
        params_update_asset_group[:assets].filter_map do |uuid_or_barcode|
          Asset.find_or_import_asset_with_barcode(uuid_or_barcode)
        end.uniq
    )
  end

  def show_alert(data)
    @alerts = [] unless @alerts
    @alerts.push(data)
  end

  def printer_config
    # We permit the entire hash, as we just use it for lookup.
    request_config = params.fetch(:printer_config, {}).permit!
    @current_user.printer_config.merge(request_config)
  end

  def params_update_asset_group
    params.require(:asset_group).permit(assets: [])
  end
end
