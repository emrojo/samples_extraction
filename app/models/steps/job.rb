module Steps::Job # rubocop:todo Style/Documentation
  def create_job
    save_job(delay(queue: 'steps').perform_job)
  end

  def save_job(delayed_job)
    delayed_job.save
    self.job_id = delayed_job.id
    save!
  end

  def clear_job
    self.job_id = nil
    @error = nil
    save!
  end

  def save_error_output
    self.output = output_error(@error)
    self.job_id = job ? job.id : nil
    save!
  end

  def output_error(exception)
    return output unless exception

    [output, exception && exception.message, Rails.backtrace_cleaner.clean(exception && exception.backtrace)].flatten
      .join("\n")
  end

  def job
    job_id ? Delayed::Job.find(job_id) : nil
  end

  def perform_job
    @error = nil
    begin
      process
    rescue StandardError => e
      @error = e
      true
    else
      reload
      complete! if running?
    end
  ensure
    fail! unless stopped? || ignored? || completed?
  end
end
