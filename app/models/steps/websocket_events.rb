module Steps::WebsocketEvents # rubocop:todo Style/Documentation
  def can_unset_activity_running?
    (self.kind_of?(Step) && completed? && next_step.nil? && activity)
  end

  def unset_activity_running
    activity.in_progress!
    activity.touch
  end

  def wss_event
    [activity].concat(activities_affected).compact.uniq.each(&:touch)
  end
end
