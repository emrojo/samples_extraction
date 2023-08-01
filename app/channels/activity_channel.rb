class ActivityChannel < ApplicationCable::Channel # rubocop:todo Style/Documentation
  def self.connection_for_redis
    ActionCable.server.pubsub.redis_connection_for_subscriptions
  end

  def connection_for_redis
    self.class.connection_for_redis
  end

  def self.redis
    self.connection_for_redis
  end

  def redis
    connection_for_redis
  end

  def self.subscribed_ids
    value = connection_for_redis.get('SUBSCRIBED_IDS')
    return [] unless value

    JSON.parse(value)
  end

  def receive(data)
    process_asset_group(strong_params_for_asset_group(data)) if data['asset_group']
    process_activity(strong_params_for_activity(data)) if data['activity']
  end

  #
  # Struct type class to store the information related to a user provided input
  # input: str, with the contents that we are going to process as input
  # raw_input: str, with the original contents for the input before pre-process
  # pos: integer, position of the user input in the original list of inputs
  # result: Asset, resolved object for the user input
  class BarcodeInput
    attr_reader :input, :raw_input, :pos
    attr_accessor :result

    def initialize(options)
      @input = options[:input]
      @raw_input = options[:raw_input]
      @pos = options[:pos]
    end
  end

  #
  # Struct type class to handle assets after it has been resolved
  # together with the failing inputs
  # assets: List<Asset>, list of resolved assets
  # missing_inputs: List<str>, list of all inputs that didnt have a match
  class BarcodeInputResolvedAssets
    attr_reader :assets, :missing_inputs
    def initialize(options)
      @assets = options[:assets]
      @missing_inputs = options[:missing_inputs]
    end
  end

  # Class that will handle resolving a user input into an Asset from the
  # database. It supports 3 different types of user inputs:
  # 1. UUID of an asset, which it will be resolved into the Asset it represents
  # 2. Machine barcode of an asset, which it will be converted to human barcode
  # and resolved into the Asset
  # 3. Human barcode of an asset, which it will be resolved into the Asset it
  # represents
  class BarcodeInputResolver
    def initialize
      @input_objects_uuids = []
      @input_objects_human_barcodes = []
      @pos = 0
    end

    # Adds a new input to the resolver, classifying it into UUID or human barcode
    def add_input(input)
      return if input.blank?
      if TokenUtil.is_uuid?(input)
        @input_objects_uuids.push(BarcodeInput.new(input: input, raw_input: input, pos: _next_position))
      else
        human_barcode = TokenUtil.human_barcode(input)
        transformed_value = human_barcode.length.positive? ? human_barcode : input
        @input_objects_human_barcodes.push(
          BarcodeInput.new(input: transformed_value, raw_input: input, pos: _next_position)
        )
      end
    end

    # Returns a BarcodeInputResolvedAssets with the resolution of the Assets
    # from the inputs added
    def resolved_assets
      BarcodeInputResolvedAssets.new(
        assets: _resolved_objects.reject { |input| input.result.nil? }.map(&:result),
        missing_inputs: _resolved_objects.select { |input| input.result.nil? }.map(&:raw_input)
      )
    end

    private

    # Next number in position for the new input added.
    def _next_position
      @pos += 1
    end

    # Add the results for the resolution of the inputs provided
    def _add_results_for_input_objects(inputs)
      return unless inputs
      results = yield
      inputs.zip(results).each { |input, result| input.result = result }
    end

    # Resolves all UUIDs read into Assets sorted by the order they were found, or
    # with a nil value if they position was not found and maps them together
    def _resolve_objects_uuids
      _add_results_for_input_objects(@input_objects_uuids) do
        uuids = @input_objects_uuids.map(&:input)
        assets = Asset.where(uuid: uuids).to_a
        uuids.map { |uuid| assets.detect { |a| a.uuid == uuid unless a.nil? } }
      end
    end

    # Resolves all human barcodes read into Assets or return nil if the position
    # was not found
    def _resolve_objects_human_barcodes
      _add_results_for_input_objects(@input_objects_human_barcodes) do
        inputs = inputs = @input_objects_human_barcodes.map(&:input)
        Asset.find_or_import_assets_with_barcodes(inputs)
        assets = Asset.where(barcode: inputs).to_a
        inputs.map { |input| assets.detect { |a| a.barcode == input unless a.nil? } }
      end
    end

    # Sorts the list of inputs
    def _sorted_input_objects
      @input_objects_uuids.concat(@input_objects_human_barcodes).sort_by(&:pos)
    end

    # Resolves all inputs into the Assets they represent. Caches the value and
    # returns it in subsequents calls
    def _resolved_objects
      return @resolved_objects if @resolved_objects
      _resolve_objects_uuids
      _resolve_objects_human_barcodes
      @resolved_objects = _sorted_input_objects
    end
  end

  # Process all inputs and resolves them into a BarcodeInputResolvedAssets object
  def resolve_assets_from_inputs(inputs)
    resolver = BarcodeInputResolver.new
    inputs.each { |input| resolver.add_input(input) }
    resolver.resolved_assets
  end

  def process_asset_group(strong_params)
    asset_group = AssetGroup.find(strong_params[:id])
    inputs = strong_params[:assets]

    # @todo This probably shouldn't a be a silent failure, and we should instead
    # throw something akin to ActionController::ParameterMissing but I'm not
    # currently sure what we expect here. So maintaining existing behaviour.
    return unless inputs

    begin
      resolved_inputs = resolve_assets_from_inputs(inputs)
      asset_group.update_with_assets(resolved_inputs.assets)

      if resolved_inputs.missing_inputs.present?
        asset_group.activity.report_error("Could not find barcodes: #{resolved_inputs.missing_inputs.to_sentence}")
      end
    rescue Errno::ECONNREFUSED => e
      asset_group.activity.report_error('Cannot connect with sequencescape')
    rescue StandardError => e
      logger.error(e.backtrace.join("\n"))
      asset_group.activity.report_error(e.message)
    end
  end

  def process_activity(strong_params)
    activity = Activity.find(params[:activity_id])

    obj = ActivityChannel.activity_attributes(params[:activity_id])

    %w[stepTypes stepsPending stepsRunning stepsFailed stepsFinished].reduce(obj) do |memo, key|
      memo[key] = !!strong_params[key] unless strong_params[key].nil?
      memo
    end

    redis.hset('activities', params[:activity_id], obj.to_json)

    activity.touch
  end

  def self.default_activity_attributes
    { stepTypes: true, stepsPending: true, stepsRunning: true, stepsFailed: true, stepsFinished: false }
  end

  def self.activity_attributes(id)
    JSON.parse(redis.hget('activities', id)) || default_activity_attributes
  rescue StandardError => e
    default_activity_attributes
  end

  def strong_params_for_asset_group(params)
    params = ActionController::Parameters.new(params)
    params.require(:asset_group).permit(:id, assets: [])
  end

  def strong_params_for_activity(params)
    params = ActionController::Parameters.new(params)
    params.require(:activity).permit(:id, :stepTypes, :stepsPending, :stepsRunning, :stepsFailed, :stepsFinished)
  end

  def subscribed_ids
    self.class.subscribed_ids
  end

  def stream_id
    "activity_#{params[:activity_id]}"
  end

  def subscribed
    previous_value = subscribed_ids || []
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.push(stream_id)) unless previous_value.include?(stream_id)

    stream_from stream_id
  end

  def unsubscribed
    previous_value = subscribed_ids
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.reject { |v| v == stream_id })

    stop_all_streams
  end
end
