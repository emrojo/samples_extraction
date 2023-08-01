module Steps::Cancellable # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval do
      scope :newer_than, ->(step) { where("id > #{step.id}").includes(:operations, :step_type) }
      scope :older_than, ->(step) { where("id < #{step.id}").includes(:operations, :step_type) }
    end
  end

  def cancel_me_and_any_newer_completed_steps
    save_job(delay(queue: 'steps')._cancel_me_and_any_newer_completed_steps)
  end

  def remake_me_and_any_older_cancelled_steps
    save_job(delay(queue: 'steps')._remake_me_and_any_older_cancelled_steps)
  end

  def cancel_me
    save_job(delay(queue: 'steps')._cancel_me)
  end

  def remake_me
    save_job(delay(queue: 'steps')._remake_me)
  end

  def cancellable?
    true
  end

  def steps_newer_than_me
    return Step.none unless activity

    activity.steps.newer_than(self)
  end

  def steps_older_than_me
    return Step.none unless activity

    activity.steps.older_than(self)
  end

  def _cancel_me
    ActiveRecord::Base.transaction do
      fact_changes_for_option(:cancel).apply(self, false)
      operations.update_all(cancelled?: true)
    end
  end

  def _remake_me
    ActiveRecord::Base.transaction do
      fact_changes_for_option(:remake).apply(self, false)
      operations.update_all(cancelled?: false)
    end
  end

  def _cancel_me_and_any_newer_completed_steps(change_state = true)
    changes =
      [
          fact_changes_for_option(:cancel),
          steps_newer_than_me.completed.map { |s| s.fact_changes_for_option(:cancel) }
        ].flatten
        .compact
        .reduce(FactChanges.new) { |memo, updates| memo.merge(updates) }

    ActiveRecord::Base.transaction do
      changes.apply(self, false)
      steps_newer_than_me.completed.each(&:cancelled!)
      operations.update_all(cancelled?: true)
      cancelled! if change_state
    end
  end

  def _remake_me_and_any_older_cancelled_steps
    changes =
      [
          steps_older_than_me.cancelled.map { |s| s.fact_changes_for_option(:remake) },
          fact_changes_for_option(:remake)
        ].flatten
        .compact
        .reduce(FactChanges.new) { |memo, updates| memo.merge(updates) }

    ActiveRecord::Base.transaction do
      changes.apply(self, false)
      steps_older_than_me.cancelled.each(&:complete!)
      operations.update_all(cancelled?: false)
      complete!
    end
  end

  def fact_changes_for_option(option_name)
    operations.reduce(FactChanges.new) do |updates, operation|
      operation.generate_changes_for(option_name, updates)
      updates
    end
  end
end
