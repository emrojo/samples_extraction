class SamplesNotStartedController < SamplesStatusController # rubocop:todo Style/Documentation
  private

  def get_assets_for_activity_type(activity_type)
    activity_type.assets.not_started.preload(:facts).paginate(pagination_params_for_activity_type(activity_type))
  end
end
