require 'parsers/csv_layout'
require 'parsers/csv_layout_with_tube_creation'
require 'parsers/csv_order'
require 'parsers/symphony'

module Lab::Actions

  class InvalidDataParams < StandardError
    attr_accessor :error_params

    def initialize(message = nil, error_params = nil)
      super(html_error_message([message].flatten))
      @error_params = error_params
    end

    def html_error_message(error_messages)
      ['<ul>', error_messages.map do |msg|
        ['<li>',msg,'</li>']
      end, '</ul>'].flatten.join('')
    end

  end

  def get_step_for(step_type)
    Step.new(step_type: step_type)
  end

  def unrack_tubes(list_layout, destination_rack=nil, step=nil)
    tubes = list_layout.map{|obj| obj[:asset]}.compact
    return if tubes.empty?
    facts_to_destroy = []
    tubes_ids = tubes.map(&:id)
    tubes.each_with_index do |tube, index|
      location_facts = tube.facts.with_predicate('location')
      unless location_facts.empty?
        location = location_facts.first.object
        facts_to_destroy.push(tube.facts.with_predicate('location'))
      end
      tube.facts.with_predicate('parent').each do |parent_fact|
        previous_rack = parent_fact.object_asset
        previous_rack.facts.with_predicate('contains').each do |contain_fact|
          if tubes_ids.include?(contain_fact.object_asset_id)
            facts_to_destroy.push(contain_fact)
          end
        end

        if destination_rack
          #tube.add_fact()
          rerack = Asset.create
          step.add_fact(rerack, Fact.create(predicate: 'a', object: 'Rerack'))
          step.add_fact(rerack, Fact.create(predicate: 'tube', object_asset: tube))
          step.add_fact(rerack, Fact.create(predicate: 'previousParent', object_asset: previous_rack))
          step.add_fact(rerack, Fact.create(predicate: 'previousLocation', object: location))
          step.add_fact(rerack, Fact.create(predicate: 'location', object: list_layout[index][:location]))

          step.add_fact(destination_rack, Fact.create(predicate: 'rerack', object_asset: rerack))
        end

        facts_to_destroy.push(parent_fact)
      end
    end
    facts_to_destroy = facts_to_destroy.flatten.compact
    if step
      facts_to_destroy.each{|f| f.set_to_remove_by(step.id)}
    else
      facts_to_destroy.each(&:destroy)
    end
  end

  def clean_rack(rack, step)
    rack.facts.with_predicate('contains').each do |f|
      f.set_to_remove_by(step.id)
    end
  end

  def rack_tubes(rack, list_layout, step=nil)
    ActiveRecord::Base.transaction do |t|
      unrack_tubes(list_layout, rack, step)

      facts_to_add = []

      list_layout.each do |l|
        location = l[:location]
        tube = l[:asset]
        next unless tube
        if step
          step_ref = step.id
          tube.facts.with_predicate('location').each{|f| f.set_to_remove_by(step_ref)}
        else
          step_ref = nil
          tube.facts.with_predicate('location').each(&:destroy)
        end
        step.add_facts(tube, Fact.create(:predicate => 'location', :object => location, :to_add_by => step_ref))
        step.add_facts(tube, Fact.create(:predicate => 'parent', :object_asset => rack, :to_add_by => step_ref))
        step.add_facts(rack, Fact.create(:predicate => 'contains', :object_asset => tube, :to_add_by => step_ref))
      end
    end
  end

  def params_to_list_layout(params)
    params.map do |location, barcode|
      asset = Asset.find_or_import_asset_with_barcode(barcode)
      {
        :location => location, 
        :asset => asset,
        :barcode => barcode
      }
    end
  end

  def get_duplicates(list)
    list.reduce({}) do |memo, element|
      memo[element] = 0 unless memo[element]
      memo[element]+=1
      memo
    end.each_pair.select{|key, count| count > 1}
  end

  def check_duplicates(params, error_messages, error_locations)
    duplicated_locations = get_duplicates(params.map{|location, barcode| location})
    duplicated_assets = get_duplicates(params.map{|location, barcode| barcode})

    duplicated_locations.each do |location, count|
      error_locations.push(location)
      error_messages.push("Location #{location} is appearing #{count} times")
    end

    duplicated_assets.each do |barcode, count|
      #error_locations.push(barcode)
      error_messages.push("Asset #{barcode} is appearing #{count} times")      
    end
  end  

  def check_racking_barcodes(list_layout, error_messages, error_locations)
    list_layout.each do |obj|
      location = obj[:location]
      asset = obj[:asset]
      barcode = obj[:barcode]
      if (asset.nil? && !barcode.nil? && !barcode.starts_with?('F'))
        error_locations.push(location)
        error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
      end
    end
  end

  def check_tuberacks(list_layout, error_messages, error_locations)
    if asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the racking process")
    end    
  end

  def check_types_for_racking(list_layout, step_type, error_messages, error_locations)
    unless step_type.compatible_with?(list_layout.map{|obj| obj[:asset]}.concat(asset_group.assets).sort.uniq)
      error_messages.push("Some of the assets provided have an incompatible type with the racking step defined")
    end    
  end

  def check_collisions(rack, list_layout, error_messages, error_locations)
    tubes_for_rack = rack.facts.with_predicate('contains').map(&:object_asset)
    tubes_for_rack.each do |tube|
      tube_location = tube.facts.with_predicate('location').first.object
      list_layout.each do |obj|
        next unless obj[:asset]
        if (tube_location == obj[:location])
          if (obj[:asset] != tube)
            error_messages.push(
              "Tube #{obj[:asset].barcode} cannot be put at location #{obj[:location]} because the tube #{tube.barcode || tube.uuid} is there"
              )
          end
        end
      end
      unless (list_layout.map{|obj| obj[:asset]}.include?(tube))
        # Remember that the tubes needs to be always in a rack. They cannot be interchanged 
        # in between racks
        error_messages.push(
              "Missing tube!! Any tube already existing in the rack can't disappear from its defined layout without being reracked before. Tube #{tube.barcode || tube.uuid} should be present in the rack at location #{tube_location} but is missed from the rack."
        )
      end
    end

  end

  def racking(step_type, params)
    step = get_step_for(step_type)

    error_messages = []
    error_locations = []

    check_duplicates(params["racking"], error_messages, error_locations)

    unless error_messages.empty?
      raise InvalidDataParams.new(error_messages, error_locations)
    end

    list_layout = params_to_list_layout(params["racking"])
    rack = asset_group.assets.with_fact('a', 'TubeRack').uniq.first

    check_collisions(rack, list_layout, error_messages, error_locations)

    check_racking_barcodes(list_layout, error_messages, error_locations)
    check_tuberacks(list_layout, error_messages, error_locations)
    check_types_for_racking(list_layout, step_type, error_messages, error_locations)

    if error_messages.empty?
      rack_tubes(rack, list_layout, step)
    else
      raise InvalidDataParams.new(error_messages, error_locations)
    end
  end

  def linking(step_type, params)
    return if params.nil?
    pairing = Pairing.new(params["pairings"], step_type)

    if pairing.valid?
      ActiveRecord::Base.transaction do |t|
        pairing.each_pair_assets do |pair_assets|
          progress_with({:assets => pair_assets, :state => 'in_progress'})
        end
      end
    else
      raise InvalidDataParams, pairing.error_messages
    end
  end

  def csv_parsing(step_type, params, class_type)
    error_messages = []
    error_locations = []
    parser = class_type.new(params[:file].read)

    if activity.asset_group.assets.with_fact('a', 'TubeRack').empty?
      error_messages.push("No TubeRacks found to perform the layout process")
    end
    if activity.asset_group.assets.with_fact('a', 'TubeRack').count > 1
      error_messages.push("Too many TubeRacks found to perform the layout process")
    end
    raise InvalidDataParams.new(error_messages) if error_messages.count > 0

    asset = activity.asset_group.assets.with_fact('a', 'TubeRack').first

    if parser.valid?
      rack = asset
      list_layout = parser.layout
      check_collisions(rack, list_layout, error_messages, error_locations)

      check_racking_barcodes(list_layout, error_messages, error_locations)
      check_tuberacks(list_layout, error_messages, error_locations)
      #check_types_for_racking(list_layout, step_type, error_messages, error_locations)
    end

    unless error_messages.empty?
      raise InvalidDataParams.new(error_messages)
    end

    if parser.valid?
      ActiveRecord::Base.transaction do |t|
        unless rack_tubes(asset, parser.layout, self)# parser.add_facts_to(asset, self)
          raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]}) 
        end

        error_messages.push(asset.validate_rack_content)
        raise InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
      end
    else
      raise InvalidDataParams.new(parser.errors.map{|e| e[:msg]})
    end
  end

  def layout(step_type, params)
    csv_parsing(step_type, params, Parsers::CsvLayout)
  end

  def layout_creating_tubes(step_type, params)
    csv_parsing(step_type, params, Parsers::CsvLayoutWithTubeCreation)
  end

  def samples_symphony(step_type, params)
    rack = activity.asset_group.assets.with_fact('a', 'TubeRack').first
    msgs = Parsers::Symphony.parse(params[:file].read, rack)
    raise InvalidDataParams.new(msgs) if msgs.length > 0
  end

end
