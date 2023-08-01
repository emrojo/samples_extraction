module StepExecutionProcess # rubocop:todo Style/Documentation
  def run
    return false unless compatible?

    plan
    step.reload
    if step.stopped?
      return stop!
    else
      apply
    end
  end
end
