# frozen_string_literal: true

module StepPlanner
  # # This rule applies the barcodes from a rack into a plate
  # {
  #   ?plate se:a Plate .
  #   ?rack se:a TubeRack .
  #   ?rack se:mergeInto ?plate .
  #   ?rack se:contains ?tube .
  #   ?plate se:contains ?well .
  #   ?tube se:location ?location .
  #   ?tube se:barcode ?barcode .
  #   ?well se:location ?location .
  #   } => {
  #     :step :addFacts { ?well se:barcode ?barcode . } .
  #     :step :removeFacts { ?tube se:barcode ?barcode . } .
  #     :step :addFacts { ?tube se:barcode  . } .
  #     :step :addFacts { ?tube se:previousBarcode ?barcode . } .
  #     :step :addFacts { ?tube se:appliedBarcodeTo ?well . } .
  #     :step :addFacts { ?rack se:mergedInto ?plate .}.
  #     :step :addFacts { ?plate se:mergedFrom ?rack .}.
  #   }.
  class MoveBarcodesFromTubeRackToPlate
    attr_reader :asset_group

    delegate :assets, to: :asset_group

    def initialize(asset_group_id, _step_id)
      @asset_group = AssetGroup.includes(assets: { facts: { object_asset: :facts } }).find(asset_group_id)
    end

    def assets_compatible_with_step_type
      # @note I'm not sure why any? is accepted here, I'd have thought we'd want both
      # plus failing silently in the event we have nothing to do seem undesireable
      [plate, tube_rack].any?
    end

    def plate
      @plate ||= assets.detect { |a| a.predicate_matching?('a', 'Plate') }
    end

    def tube_rack
      @tube_rack ||= assets.detect { |a| a.predicate_matching?('a', 'TubeRack') }
    end

    def wells_for(asset)
      asset.facts.with_predicate('contains').map(&:object_asset)
    end

    def index_wells_in(asset)
      wells_for(asset).index_by { |well| location_of(well) }
    end

    def traverse_wells(asset)
      wells_for(asset).each { |well| yield well, location_of(well) }
    end

    def location_of(well)
      locations = well.facts.with_predicate('location').map(&:object).uniq

      # Detect situations where we have no location, or multiple contradictory
      # locations.
      # We don't seem to have any case of the latter occurring in the production
      # database, although there are some historic records with multiple
      # location facts with the same location.
      unless locations.one?
        raise StandardError, "Could not identify location for Asset #{well.id}. Possible locations: #{locations}"
      end
      TokenUtil.pad_location(locations.first)
    end

    def process
      FactChanges.new.tap do |updates|
        if assets_compatible_with_step_type
          plate_wells = index_wells_in(plate)
          traverse_wells(tube_rack) do |well_from_tube_rack, location|
            well_from_plate = plate_wells.fetch(TokenUtil.pad_location(location))
            barcode = well_from_tube_rack.barcode
            updates.remove_where(well_from_tube_rack, 'barcode', barcode)
            updates.add(well_from_tube_rack, 'previousBarcode', barcode)
            updates.add(well_from_tube_rack, 'appliedBarcodeTo', well_from_plate)
            well_from_tube_rack.update(barcode: nil)
            well_from_plate.update(barcode: barcode)
            updates.add(well_from_plate, 'barcode', barcode)
          end

          updates.add(tube_rack, 'mergedInto', plate)
          updates.add(plate, 'mergedFrom', tube_rack)
        end
      end
    end

    def updates
      ActiveRecord::Base.transaction { process }
    rescue StandardError => e
      { set_errors: ["Unknown error while applying barcodes: #{e.message}, #{e.backtrace}"] }
    end
  end
end
