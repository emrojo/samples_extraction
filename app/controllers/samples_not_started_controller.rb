# frozen_string_literal: true
class SamplesNotStartedController < ApplicationController
  def index
    @activity_types = ActivityType.all.visible.sort_by(&:name).uniq

    @assets_for_activity_types = @activity_types.map do |activity_type|
      {
        activity_type: activity_type,
        assets: activity_type.assets.not_started.paginate(pagination_params_for_activity_type(activity_type))
        #:assets => assets_paginated
        #:assets => Asset.not_started.compatible_with_activity_type(activity_type).paginate(pagination_params_for_activity_type(activity_type))
      }
    end

    @activity_type_selected = ActivityType.find_by_id(samples_started_params[:activity_type_id])
  end

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
end
