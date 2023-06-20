class RerackingController < ApplicationController # rubocop:todo Style/Documentation
  before_action :set_activity_type
  before_action :set_activity, only: %i[update show]

  def set_activity_type
    @activity_type = ActivityType.not_deprecated.where(name: 'Re-Racking').last
  end

  def index
    @activity = Activity.new
  end
end
