require 'parsers/csv_layout/csv_parser'
require 'parsers/csv_layout/barcode_creatable_parser'
require 'parsers/csv_layout/validators/any_barcode_validator'

require 'fact_changes'

class InvalidDataParams < StandardError # rubocop:todo Style/Documentation
  attr_accessor :errors

  def initialize(message = nil)
    super(message)
    @errors = message
  end

  def html_error_message(error_messages)
    ['<ul>', error_messages.map { |msg| ['<li>', msg, '</li>'] }, '</ul>'].flatten.join
  end
end

module Actions
  module Racking # rubocop:todo Style/Documentation
    DNA_STOCK_PLATE_PURPOSE = 'DNA Stock Plate'
    RNA_STOCK_PLATE_PURPOSE = 'RNA Stock Plate'
    STOCK_PLATE_PURPOSE = 'Stock Plate'
    DNA_ALIQUOT = 'DNA'
    RNA_ALIQUOT = 'RNA'
    TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES = %w[study_name aliquotType]

    ALIQUOT_PURPOSE = { DNA_ALIQUOT => DNA_STOCK_PLATE_PURPOSE, RNA_ALIQUOT => RNA_STOCK_PLATE_PURPOSE }

    # Actions
    def rack_layout(options = {})
      csv_parsing(Parsers::CsvLayout::CsvParser.new(selected_file.data, options))
    end

    def rack_layout_creating_tubes
      rack_layout(barcode_parser: Parsers::CsvLayout::BarcodeCreatableParser)
    end

    def rack_layout_any_barcode
      rack_layout(barcode_validator: Parsers::CsvLayout::Validators::AnyBarcodeValidator)
    end

    # Support methods and classes

    def reracking_tubes(rack, list_layout)
      FactChanges.new.tap do |facts_changes|
        fact_changes_for_unrack_tubes(list_layout, rack, facts_changes)
        fact_changes_for_rack_tubes(list_layout, rack, facts_changes)
      end
    end

    private

    def fact_changes_for_unrack_tubes(list_layout, destination_rack, updates)
      rerack_group = nil
      previous_racks = []
      tubes = list_layout.pluck(:asset)

      list_layout.map do |layout|
        tube = layout[:asset]
        next if tube.nil?
        location_facts = tube.facts.with_predicate('location')
        previous_location = location_facts.first&.object
        updates.remove(location_facts)

        tube
          .facts
          .with_predicate('parent')
          .each do |parent_fact|
            previous_rack = parent_fact.object_asset

            unless previous_racks.include?(previous_rack)
              previous_racks.push(previous_rack)
              tube_ids = tubes.map(&:id)
              old_facts =
                previous_rack.facts.with_predicate('contains').select { |fact| tube_ids.include?(fact.object_asset_id) }
              updates.remove(old_facts)
            end

            unless rerack_group
              rerack_group = Asset.new
              updates.create_assets([rerack_group])
              updates.add(rerack_group, 'barcodeType', 'NoBarcode')
              updates.add(destination_rack, 'rerackGroup', rerack_group)
            end

            rerack = Asset.new
            updates.create_assets([rerack])
            updates.add(rerack, 'a', 'Rerack')
            updates.add(rerack, 'tube', tube)
            updates.add(rerack, 'barcodeType', 'NoBarcode')
            updates.add(rerack, 'previousParent', previous_rack) if previous_rack.present?
            updates.add(rerack, 'previousLocation', previous_location) if previous_location.present?

            updates.add(rerack, 'location', layout[:location])
            updates.add(rerack_group, 'rerack', rerack)

            updates.remove(parent_fact)
          end
      end

      # sync rack property
      previous_racks.each { |previous_rack| fact_changes_for_rack_when_unracking_tubes(previous_rack, tubes, updates) }
    end

    def purpose_for_aliquot(aliquot)
      ALIQUOT_PURPOSE.fetch(aliquot, STOCK_PLATE_PURPOSE)
    end

    def fact_changes_for_add_purpose(rack, aliquot)
      FactChanges.new.tap { |updates| updates.add(rack, 'purpose', purpose_for_aliquot(aliquot)) }
    end

    def fact_changes_for_remove_purpose(rack, aliquot)
      FactChanges.new.tap { |updates| updates.remove_where(rack, 'purpose', purpose_for_aliquot(aliquot)) }
    end

    # For a plate modified (any plate that is losing a tube), it will resync the values of inherited
    # properties from the plates with the current list of tubes it contains
    def fact_changes_for_rack_when_unracking_tubes(rack, unracked_tubes, updates = FactChanges.new)
      tubes_from_previous_rack = rack.facts.with_predicate('contains').map(&:object_asset)
      actual_tubes = (tubes_from_previous_rack - unracked_tubes)

      TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES.each do |transferrable_property|
        unracked_tubes
          .map { |tube| tube.facts.with_predicate(transferrable_property).map(&:object) }
          .flatten
          .compact
          .each do |value|
            updates.remove_where(rack, transferrable_property, value)
            updates.merge(fact_changes_for_remove_purpose(rack, value)) if transferrable_property == 'aliquotType'
          end
        actual_tubes
          .map { |tube| tube.facts.with_predicate(transferrable_property).map(&:object).flatten.compact }
          .each do |value|
            updates.add(rack, transferrable_property, value)
            updates.merge(fact_changes_for_add_purpose(rack, value)) if transferrable_property == 'aliquotType'
          end
      end
      updates
    end

    def fact_changes_for_rack_when_racking_tubes(rack, racked_tubes, updates = FactChanges.new)
      TUBE_TO_PLATE_TRANSFERRABLE_PROPERTIES
        .map { |prop| racked_tubes.map { |tube| tube.facts.with_predicate(prop) } }
        .flatten
        .compact
        .each do |fact|
          updates.add(rack, fact.predicate.to_s, fact.object_value)
          updates.merge(fact_changes_for_add_purpose(rack, fact.object_value)) if fact.predicate.to_s == 'aliquotType'
        end
      updates
    end

    def put_tube_into_rack_position(tube, rack, location, updates)
      updates.remove(tube.facts.with_predicate('location'))
      updates.add(tube, 'location', location)
      updates.add(tube, 'parent', rack)
      updates.add(rack, 'contains', tube)
    end

    def fact_changes_for_rack_tubes(list_layout, rack, updates)
      tubes =
        list_layout.filter_map do |l|
          location = l[:location]
          tube = l[:asset]
          next unless tube

          put_tube_into_rack_position(tube, rack, location, updates)
          tube
        end
      fact_changes_for_rack_when_racking_tubes(rack, tubes, updates)
    end

    def check_racking_barcodes(list_layout, error_messages)
      list_layout.each do |obj|
        location = obj[:location]
        asset = obj[:asset]
        barcode = obj[:barcode]
        if asset.nil? && !barcode.nil? && !barcode.starts_with?('F')
          error_messages.push("Barcode #{barcode} scanned at #{location} is not in the database")
        end
      end
    end

    def check_collisions(list_layout, error_messages)
      tubes_for_rack = tube_rack.facts.with_predicate('contains').map(&:object_asset)
      tubes_for_rack.each do |tube|
        tube_location = tube.facts.with_predicate('location').first.object
        list_layout.each do |obj|
          next unless obj[:asset]

          if tube_location == obj[:location]
            if obj[:asset] != tube
              error_messages.push(
                # rubocop:todo Layout/LineLength
                "Tube #{obj[:asset].barcode} cannot be put at location #{obj[:location]} because the tube #{tube.barcode || tube.uuid} is there"
                # rubocop:enable Layout/LineLength
              )
            end
          end
        end
        if list_layout.none? { |obj| obj[:asset] == tube }
          # Remember that the tubes needs to be always in a rack. They cannot be interchanged
          # in between racks
          error_messages.push(
            # rubocop:todo Layout/LineLength
            "Missing tube!! Any tube already existing in the rack can't disappear from its defined layout without being reracked before. Tube #{tube.barcode || tube.uuid} should be present in the rack at location #{tube_location} but is missed from the rack."
            # rubocop:enable Layout/LineLength
          )
        end
      end
    end

    def selected_file
      asset_group.uploaded_files.first
    end

    def raise_invalid_data(message)
      raise InvalidDataParams, [message]
    end

    def tube_rack
      return @tube_rack if defined?(@tube_rack)

      tube_racks =
        asset_group.assets.with_fact('a', 'TubeRack').includes(facts: { object_asset: { facts: :object_asset } })

      raise_invalid_data('No TubeRacks found to perform the layout process') if tube_racks.empty?
      raise_invalid_data('Too many TubeRacks found to perform the layout process') if tube_racks.many?

      @tube_rack = tube_racks.first
    end

    def csv_parsing(parser)
      error_messages = []

      if parser.valid?
        list_layout = parser.layout
        check_collisions(list_layout, error_messages)
        check_racking_barcodes(list_layout, error_messages)
      else
        raise InvalidDataParams, parser.error_list
      end

      raise InvalidDataParams, error_messages unless error_messages.empty?

      updates = parser.parsed_changes.merge(reracking_tubes(tube_rack, parser.layout))

      error_messages.concat(tube_rack.validate_rack_content)
      raise InvalidDataParams, error_messages if error_messages.flatten.compact.count > 0

      updates
    end
  end
end
