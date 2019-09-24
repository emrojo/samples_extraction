require 'parsers/csv_layout/csv_parser'
require 'parsers/csv_layout/barcode_creatable_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'

require 'fact_changes'

class InvalidDataParams < StandardError
  attr_accessor :errors

  def initialize(message = nil)
    super(message)
    @errors = message
    #@msg = html_error_message([message].flatten)
  end

  def html_error_message(error_messages)
    ['<ul>', error_messages.map do |msg|
      ['<li>',msg,'</li>']
    end, '</ul>'].flatten.join('')
  end

end

module Actions
  module Racking

    DNA_STOCK_PLATE_PURPOSE = 'DNA Stock Plate'
    RNA_STOCK_PLATE_PURPOSE = 'RNA Stock Plate'
    STOCK_PLATE_PURPOSE = 'Stock Plate'
    DNA_ALIQUOT = 'DNA'
    RNA_ALIQUOT = 'RNA'
    TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES = [:study_name,:aliquotType]

    # Actions
    def rack_layout(asset_group)
      content = selected_file(asset_group).data
      csv_parsing(asset_group, Parsers::CsvLayout::CsvParser.new(content))
    end

    def rack_layout_creating_tubes(asset_group)
      content = selected_file(asset_group).data
      parser = Parsers::CsvLayout::CsvParser.new(content, {
        barcode_parser: Parsers::CsvLayout::BarcodeCreatableParser
      })
      csv_parsing(asset_group, parser)
    end

    def rack_layout_any_barcode(asset_group)
      content = selected_file(asset_group).data
      parser = Parsers::CsvLayout::CsvParser.new(content, {
        barcode_validator: Parsers::CsvLayout::Validators::AnyBarcodeValidator
      })
      csv_parsing(asset_group, parser)
    end

    # Support methods and classes


    def clean_rack(rack)
      remove_facts(facts.with_predicate('contains'))
    end

    def reracking_tubes(rack, list_layout)
      fact_changes_unrack = fact_changes_for_unrack_tubes(list_layout, rack)
      fact_changes_rack = fact_changes_for_rack_tubes(list_layout, rack)
      fact_changes_unrack.merge(fact_changes_rack)
    end

    def fact_changes_for_unrack_tubes(list_layout, destination_rack=nil)
      FactChanges.new.tap do |updates|
        rerackGroup=nil

        previous_racks = []
        tubes = list_layout.map{|obj| obj[:asset]}.compact
        return updates if tubes.empty?
        tubes_ids = tubes.map(&:id)
        tubes_list = Asset.where(id: tubes_ids).includes(:facts)
        tubes_list.each_with_index do |tube, index|
          location_facts = tube.facts.with_predicate('location')
          unless location_facts.empty?
            location = location_facts.first.object
            updates.remove(tube.facts.with_predicate('location'))
          end
          tube.facts.with_predicate('parent').each do |parent_fact|
            previous_rack = parent_fact.object_asset
            unless (previous_racks.include?(previous_rack))
              previous_racks.push(previous_rack)
              updates.remove(previous_rack.facts.with_predicate('contains').where(object_asset_id: tubes_ids))
            end

            if destination_rack
              unless rerackGroup
                rerackGroup = Asset.new
                updates.create_assets([rerackGroup])
                updates.add(rerackGroup, 'barcodeType', 'NoBarcode')
                updates.add(destination_rack, 'rerackGroup', rerackGroup)
              end

              rerack = Asset.new
              updates.create_assets([rerack])
              updates.add(rerack, 'a', 'Rerack')
              updates.add(rerack, 'tube', tube)
              updates.add(rerack, 'barcodeType', 'NoBarcode')
              updates.add(rerack, 'previousParent', previous_rack)
              updates.add(rerack, 'previousLocation', location)
              updates.add(rerack, 'location', list_layout[index][:location])
              updates.add(rerackGroup, 'rerack', rerack)

              previous_racks.push(previous_rack)
            end

            updates.remove(parent_fact)
          end
        end

        # sync rack property
        previous_racks.each do |previous_rack|
          updates.merge(fact_changes_for_rack_when_unracking_tubes(previous_rack, tubes))
        end
      end
    end

    def purpose_for_aliquot(aliquot)
      if aliquot == DNA_ALIQUOT
        DNA_STOCK_PLATE_PURPOSE
      elsif aliquot == RNA_ALIQUOT
        RNA_STOCK_PLATE_PURPOSE
      else
        STOCK_PLATE_PURPOSE
      end
    end

    def fact_changes_for_add_purpose(rack, aliquot)
      FactChanges.new.tap do |updates|
        updates.add(rack, 'purpose', purpose_for_aliquot(aliquot))
      end
    end

    def fact_changes_for_remove_purpose(rack, aliquot)
      FactChanges.new.tap do |updates|
        updates.remove_where(rack, 'purpose', purpose_for_aliquot(aliquot))
      end
    end

    # For a plate modified (any plate that is losing a tube), it will resync the values of inherited
    # properties from the plates with the current list of tubes it contains
    def fact_changes_for_rack_when_unracking_tubes(rack, unracked_tubes)
      FactChanges.new.tap do |updates|
        tubes_from_previous_rack = rack.facts.with_predicate('contains').map(&:object_asset)
        actual_tubes = (tubes_from_previous_rack - unracked_tubes)

        TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES.each do |transferrable_property|
          unracked_tubes.map{|tube| tube.facts.with_predicate(transferrable_property).map(&:object)}.flatten.compact.each do |value|
            updates.remove_where(rack, transferrable_property.to_s, value)
            updates.merge(fact_changes_for_remove_purpose(rack, value)) if transferrable_property.to_s == 'aliquotType'
          end
          actual_tubes.map{|tube| tube.facts.with_predicate(transferrable_property).map(&:object).flatten.compact}.each do |value|
            updates.add(rack, transferrable_property.to_s, value)
            updates.merge(fact_changes_for_add_purpose(rack, value)) if transferrable_property.to_s == 'aliquotType'
          end
        end
      end
    end

    def fact_changes_for_rack_when_racking_tubes(rack, racked_tubes)
      FactChanges.new.tap do |updates|
        TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES.map do |prop|
          racked_tubes.map{|tube| tube.facts.with_predicate(prop)}
        end.flatten.compact.each do |fact|
          updates.add(rack, fact.predicate.to_s, fact.object_value)
          updates.merge(fact_changes_for_add_purpose(rack, fact.object_value)) if fact.predicate.to_s == 'aliquotType'
        end
      end
    end

    def put_tube_into_rack_position(tube, rack, location)
      FactChanges.new.tap do |updates|
        updates.remove(tube.facts.with_predicate('location'))
        updates.add(tube, 'location', location)
        updates.add(tube, 'parent', rack)
        updates.add(rack, 'contains', tube)
      end
    end

    def remove_tube_from_rack(tube, rack)
      FactChanges.new.tap do |updates|
        updates.remove(tube.facts.with_predicate('location'))
        updates.remove_where(rack, 'contains', tube)
      end
    end

    def fact_changes_for_rack_tubes(list_layout, rack)
      FactChanges.new.tap do |updates|
        tubes = []
        list_layout.each do |l|
          location = l[:location]
          tube = l[:asset]
          next unless tube
          tubes.push(tube)
          updates.merge(put_tube_into_rack_position(tube, rack, location))
        end
        updates.merge(fact_changes_for_rack_when_racking_tubes(rack, tubes))
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

    def check_tuberacks(asset_group, list_layout, error_messages, error_locations)
      if asset_group.assets.with_fact('a', 'TubeRack').empty?
        error_messages.push("No TubeRacks found to perform the racking process")
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

    def selected_file(asset_group)
      asset_group.uploaded_files.first
    end

    def csv_parsing(asset_group, parser)
      error_messages = []
      error_locations = []

      if asset_group.assets.with_fact('a', 'TubeRack').empty?
        error_messages.push("No TubeRacks found to perform the layout process")
      end
      if asset_group.assets.with_fact('a', 'TubeRack').count > 1
        error_messages.push("Too many TubeRacks found to perform the layout process")
      end
      raise InvalidDataParams.new(error_messages) if error_messages.count > 0

      asset = asset_group.assets.with_fact('a', 'TubeRack').first

      if parser.valid?
        rack = asset
        list_layout = parser.layout
        check_collisions(rack, list_layout, error_messages, error_locations)

        check_racking_barcodes(list_layout, error_messages, error_locations)
        check_tuberacks(asset_group, list_layout, error_messages, error_locations)
      end

      unless error_messages.empty?
        raise InvalidDataParams.new(error_messages)
      end
      if parser.valid?
        updates = parser.parsed_changes.merge(reracking_tubes(asset, parser.layout))

        error_messages.push(asset.errors) unless asset.valid?
        #error_messages.push(asset.validate_rack_content)
        raise InvalidDataParams.new(error_messages) if error_messages.flatten.compact.count > 0
        return updates
      else
        raise InvalidDataParams.new(parser.error_list)
      end
    end


    def samples_symphony(step_type, params)
      rack = asset_group.assets.with_fact('a', 'TubeRack').first
      msgs = Parsers::Symphony.parse(params[:file].read, rack)
      raise InvalidDataParams.new(msgs) if msgs.length > 0
    end

  end
end
