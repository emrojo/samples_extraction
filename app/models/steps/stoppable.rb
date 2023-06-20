module Steps::Stoppable # rubocop:todo Style/Documentation
  def stop_job
    ActiveRecord::Base.transaction do
      clear_job
      if self.job_id
        job_info = Delayed::Job.find(self.job_id)
        job_info.destroy unless job_info.locked_at?
      end
    end
  end

  def continue_newer_steps
    activity.steps.newer_than(self).stopped.each(&:continue!)
  end

  def stop_newer_steps
    activity.steps.newer_than(self).active.each(&:stop!)
  end
end
