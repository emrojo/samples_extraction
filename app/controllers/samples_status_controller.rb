#
# Abstract class that both the started and not started samples view will implement.
class SamplesStatusController < ApplicationController
  before_action :set_activity_type_selected, only: [:index]
  before_action :set_activity_types, only: [:index]
  before_action :set_assets_for_activity_types, only: [:index]

  def index; end

  private

  def pagination_params_for_activity_type(activity_type)
    if samples_started_params[:activity_type_id].to_i == activity_type.id
      { page: samples_started_params[:page], per_page: 5 }
    else
      { page: 1, per_page: 5 }
    end
  end

  def samples_started_params
    params.permit(:activity_type_id, :page)
  end

  def set_activity_type_selected
    @activity_type_selected = ActivityType.find_by_id(samples_started_params[:activity_type_id])
  end

  def set_activity_types
    @activity_types = ActivityType.visible.alphabetical
  end

  def set_assets_for_activity_types
    @assets_for_activity_types =
      @activity_types.map do |activity_type|
        { activity_type: activity_type, assets: get_assets_for_activity_type(activity_type) }
      end
  end
end
