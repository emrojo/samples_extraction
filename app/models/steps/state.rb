module Steps::State # rubocop:todo Style/Documentation
  EVENT_RUN = 'run'
  EVENT_CONTINUE = 'continue'
  EVENT_STOP = 'stop'
  EVENT_REMAKE = 'remake'
  EVENT_CANCEL = 'cancel'

  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, -> { where(in_progress?: true) }
      scope :cancelled, -> { where(state: 'cancelled') }
      scope :deprecated, -> { where(state: 'ignored') }
      scope :processing,
            -> {
              where("state = 'running' OR state = 'cancelling' OR  state = 'remaking' OR state = 'retrying'").includes(
                :operations,
                :step_type
              )
            }
      scope :running, -> { where(state: 'running').includes(:operations, :step_type) }
      scope :pending, -> { where(state: 'pending') }
      scope :failed, -> { where(state: 'failed') }
      scope :completed, -> { where(state: 'complete') }
      scope :stopped, -> { where(state: 'stopped') }
      scope :active, -> { where("state = 'running' OR state = 'pending' OR state IS NULL") }
      scope :finished, -> { includes(:operations, :step_type) }
      scope :in_activity, -> { where.not(activity_id: nil) }

      include AASM

      aasm column: :state do
        state :pending, initial: true

        state :cancelled, after_enter: :wss_event
        state :complete, after_enter: :wss_event
        state :running, after_enter: %i[deprecate_unused_previous_steps! set_start_timestamp! create_job wss_event]
        state :cancelling, after_enter: :wss_event
        state :remaking, after_enter: :wss_event
        state :failed, after_enter: :wss_event
        state :ignored
        state :stopped

        event :complete do
          transitions from: :cancelled, to: :complete
          transitions from: %i[running remaking], to: :complete, after: %i[clear_job set_complete_timestamp!]
        end

        event :cancelled do
          transitions from: %i[cancelling complete], to: :cancelled
        end

        event :run, guards: [:assets_compatible_with_step_type] do
          transitions from: %i[pending failed stopped], to: :running
        end

        event :fail do
          transitions from: %i[running failed stopped], to: :failed, after: %i[cancel_me save_error_output]
        end

        event :cancel do
          transitions from: %i[complete cancelling], to: :cancelling, after: :cancel_me_and_any_newer_completed_steps
        end

        event :remake do
          transitions from: %i[cancelled remaking], to: :remaking, after: :remake_me_and_any_older_cancelled_steps
        end

        event :continue, guards: [:assets_compatible_with_step_type] do
          transitions from: :running, to: :running
          transitions from: %i[failed stopped pending], to: :running, after: %i[continue_newer_steps run]
        end

        event :stop do
          transitions from: :stopped, to: :stopped, after: [:stop_newer_steps]
          transitions from: :cancelled, to: :stopped, after: [:stop_newer_steps]
          transitions from: :pending, to: :stopped, after: [:stop_newer_steps]
          transitions from: :complete, to: :complete, after: [:stop_newer_steps]

          transitions from: :remaking, to: :cancelled, after: %i[stop_job stop_newer_steps]
          transitions from: %i[failed running], to: :stopped, after: %i[stop_job stop_newer_steps cancel_me]
          transitions from: :cancelling, to: :complete, after: %i[stop_job stop_newer_steps]
        end

        event :ignore do
          transitions from: [:pending], to: :ignored
        end

        event :deprecate do
          transitions from: %i[failed cancelled stopped pending], to: :ignored, after: :remove_from_activity
        end
      end
    end
  end

  def set_start_timestamp!
    update_columns(started_at: Time.now.utc) if started_at.nil?
  end

  def set_complete_timestamp!
    update_columns(finished_at: Time.now.utc) if finished_at.nil?
  end

  def processing?
    is_processing_state?(state)
  end

  def is_processing_state?(state)
    return false if state.nil?

    running? || cancelling? || remaking?
  end

  def active?
    running? || pending?
    # ((self.state == 'running') || (self.state.nil?))
  end

  def completed?
    complete?
  end
end
