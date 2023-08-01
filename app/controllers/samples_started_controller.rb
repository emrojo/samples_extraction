class SamplesStartedController < SamplesStatusController # rubocop:todo Style/Documentation
  private

  def get_assets_for_activity_type(activity_type)
    activity_type
      .assets
      .started
      .joins(:activities)
      .preload(:facts, activities: [:instrument])
      .distinct(activities: :id, assets: :id)
      .order(id: :desc)
      .paginate(pagination_params_for_activity_type(activity_type))
  end
end
