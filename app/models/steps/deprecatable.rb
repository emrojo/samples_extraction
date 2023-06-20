module Steps::Deprecatable # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval { scope :deprecatable, -> { cancelled.or(failed).or(stopped) } }
  end

  def following_step_ids
    obj = self
    list = []
    loop do
      id = obj.next_step_id
      return list if id.nil?
      return list if list.include?(id)

      list.push(id)
      obj = next_step
    end
  end

  def deprecate_unused_previous_steps!
    if activity
      activity.steps.deprecatable.older_than(self).where.not(id: following_step_ids).each { |s| s.deprecate_with(self) }
    end
  end

  def after_deprecate
    deprecate!
  end

  def remove_from_activity
    self.activity = nil
    save!
  end
end
