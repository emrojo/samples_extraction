module Activities::WebsocketEvents # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval { after_commit :wss_event }
  end

  def running_inside_transaction?
    ActiveRecord::Base.connection.open_transactions == 0
  end

  def is_being_listened?
    ActivityChannel.subscribed_ids.include?(stream_id)
  end

  def send_wss_event(data)
    ActionCable.server.broadcast(stream_id, data)
  end

  def report_error(message)
    send_wss_event({ error: { type: 'danger', msg: message } })
  end

  def stream_id
    "activity_#{id}"
  end

  def websockets_attributes
    # Extract all activity attributes where the value is `false`
    rejected_keys = ActivityChannel.activity_attributes(id).filter_map { |k, v| k unless v }

    json_attributes.each_with_object({ shownComponents: {} }) do |(attribute, method), memo|
      next if rejected_keys.include?(attribute.to_s)

      memo[attribute] = method.call
    end
  end

  def wss_event(opts = {})
    if Rails.configuration.redis_enabled && is_being_listened?
      data = websockets_attributes.merge(opts)

      # debugger if data[:stepsFinished][0]['state']=='error'
      send_wss_event(data)
    end
  end
end
