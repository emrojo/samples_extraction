# frozen_string_literal: true

# Namespace for message render
module Messages
  # When an activity is completed we send a record of it to the ML Warehouse
  # This class handles the rendering of this message.
  class Activity
    # The {::Activity} that is being rendered
    attr_reader :activity

    def initialize(activity, state: 'finished')
      @activity = activity
      @state = state
    end

    # Used by warren to generate the routing key
    def routing_key
      "activity.#{@state}.#{activity.id}"
    end

    # Interface for warren. Avoids the need to wrap our message in one
    # of warren's onw Warren::Message classes
    def payload
      to_json
    end

    # Hash object used by #to_json to render the message
    def as_json(_args = {})
      { samples_extraction_activity: samples_extraction_activity, lims: 'SAMPEXT' }
    end

    def headers
      {}
    end

    private

    # Main payload of the message
    def samples_extraction_activity
      {
        samples: sample_payload,
        activity_type: activity.activity_type_name,
        instrument: activity.instrument_name,
        kit_barcode: activity.kit_barcode,
        kit_type: activity.kit_type,
        completed_at: activity.completed_at,
        updated_at: activity.updated_at,
        user: activity.last_user_fullname,
        activity_id: activity.id
      }
    end

    def sample_payload
      activity.assets.flat_map do |asset|
        input_barcode = asset.walk_transfers.barcode
        asset.sample_uuid_facts.map do |fact|
          { sample_uuid: TokenUtil.unquote(fact.object), input_barcode: input_barcode, output_barcode: asset.barcode }
        end
      end
    end
  end
end
