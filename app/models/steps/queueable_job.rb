module Steps::QueueableJob # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval do
      after_update :run_next_step, if: :can_run_next_step?
      after_commit :perform_error, if: :has_error?
    end
  end

  class ErrorOnQueuedJobProcess < StandardError
  end

  def has_error?
    state == 'error'
  end

  def perform_error
    raise @error if @error
  end

  def run_next_step
    next_step.assets_compatible_with_step_type ? next_step.run! : next_step.ignore!
  end

  def can_run_next_step?
    activity && activity.running? && completed? && next_step && !next_step.completed? && !next_step.running?
  end
end
