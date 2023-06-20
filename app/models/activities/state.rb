module Activities::State # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, -> { where(completed_at: nil) }
      scope :finished, -> { where('completed_at is not null') }
    end
  end

  def finish
    ActiveRecord::Base.transaction { update(completed_at: DateTime.now, state: 'finish') }
    after_finish if respond_to?(:after_finish)
  end

  def finished?
    !completed_at.nil?
  end

  def running?
    (steps.active.count > 0)
  end

  def editing!
    update(state: 'editing')
  end

  def in_progress!
    update(state: 'in_progress')
  end

  def editing?
    state == 'editing'
  end
end
