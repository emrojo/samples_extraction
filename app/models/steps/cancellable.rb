# frozen_string_literal: true
module Steps::Cancellable
  def self.included(klass)
    klass.instance_eval do
      scope :newer_than, ->(step) { where("id > #{step.id}") }
      scope :older_than, ->(step) { where("id < #{step.id}") }

      before_update :modify_related_steps
    end
  end

  def modify_related_steps
    if state == 'cancel' && state_was == 'complete'
      on_cancel
    elsif state == 'complete' && state_was == 'cancel'
      on_remake
    end
  end

  def steps_newer_than_me
    activity.steps.newer_than(self)
  end

  def steps_older_than_me
    activity.steps.older_than(self)
  end

  def on_cancel
    ActiveRecord::Base.transaction do
      steps_newer_than_me.each { |s| s.cancel unless s.cancelled? }
      operations.each(&:cancel)
    end
  end

  def cancelled?
    state == 'cancel'
  end

  def on_remake
    ActiveRecord::Base.transaction do
      steps_older_than_me.each do |s|
        s.remake if s.cancelled?
      end
      operations.each(&:remake)
    end
  end

  def cancel
    update_attributes(state: 'cancel')
  end

  def remake
    update_attributes(state: 'complete')
  end
end
