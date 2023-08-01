# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/tube_transfer'

class TransferTubesToTubeRackByPosition # rubocop:todo Style/Documentation
  attr_reader :asset_group

  include Actions::TubeTransfer
  def initialize(params)
    @asset_group = params[:asset_group]
  end

  #
  #  {
  #    ?p :a :Tube .
  #    ?q :a :TubeRack .
  #    ?q :contains ?r .
  #    ?r :a :Tube .
  #   }
  #    =>
  #   {
  #    ?p :transfer ?r .
  #    :step :connectBy """position""" .
  #   } .
  #

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transferToTubeRackByPosition').count > 0
  end

  def asset_group_for_execution
    AssetGroup.create!(assets: asset_group.assets.with_predicate('transferToTubeRackByPosition'))
  end

  def location_to_pos(location, max_row = 8)
    ((location[1..-1].to_i - 1) * max_row) + (location[0].ord - 'A'.ord)
  end

  def wells_for(rack)
    wells_ids = rack.facts.with_predicate('contains').map(&:object_asset_id)
    Asset.where(id: wells_ids)
  end

  def validate_enough_tubes_for_all_wells(tubes, wells, updates)
    if tubes.length > wells.length
      updates.set_errors(["This rack does not have enough spaces to allocate #{tubes.length} tubes"])
      return false
    end
    return true
  end

  def validate_tube_are_not_in_rack(rack, tubes, updates)
    facts_for_wells = Fact.where(asset_id: wells_for(rack).map(&:id))
    previous_tubes_ids = facts_for_wells.with_predicate('transferredFrom').map(&:object_asset_id)
    tubes_already_ids = previous_tubes_ids & tubes.map(&:id)
    if tubes_already_ids.length > 0
      tubes_already = Asset.where(id: tubes_already_ids).map(&:barcode)
      updates.set_errors(["This rack already contains the tubes #{tubes_already}"])
      return false
    end
    true
  end

  def validate_all_tubes_have_aliquot(tubes, updates)
    aliquot_facts = Fact.where(asset_id: tubes.map(&:id), predicate: 'aliquotType')
    unless aliquot_facts.size == tubes.size
      updates.set_errors(['Not all tubes have an aliquot associated'])
      return false
    end
    unless aliquot_facts.map(&:object).uniq.size == 1
      updates.set_errors(['Not all tubes have the same aliquot'])
      return false
    end
    true
  end

  def validate_same_aliquot_between_tubes_and_destination_plate(tubes, rack, updates)
    aliquot_tubes = Fact.where(asset_id: tubes.map(&:id), predicate: 'aliquotType').map(&:object).uniq
    if aliquot_tubes.length > 1
      updates.set_errors(['More that one different aliquot in the source tubes'])
      return false
    end
    aliquot_plate = rack.facts.where(predicate: 'aliquotType').map(&:object).uniq
    if aliquot_plate.length > 1
      updates.set_errors(['More thatn one aliquot in the destination plate'])
      return false
    end
    if aliquot_plate.length > 0
      if aliquot_tubes.first != aliquot_plate.first
        updates.set_errors(
          ["Aliquot for tubes #{aliquot_tubes.first} is different from aliquot at rack #{aliquot_plate.first}"]
        )
        return false
      end
    end
    true
  end

  def process
    FactChanges.new.tap do |updates|
      aliquot_types = []
      if assets_compatible_with_step_type
        tubes = asset_group.assets.joins(:facts).where(facts: { predicate: 'transferToTubeRackByPosition' }).uniq
        rack = tubes.first.facts.with_predicate('transferToTubeRackByPosition').first.object_asset

        return updates unless validate_tube_are_not_in_rack(rack, tubes, updates)

        wells =
          rack
            .facts
            .with_predicate('contains')
            .map(&:object_asset)
            .sort_by do |elem|
              location = elem.facts.with_predicate('location').first.object
              location_to_pos(location)
            end
            .reject { |w| w.has_predicate?('transferredFrom') }
            .uniq

        return updates unless validate_enough_tubes_for_all_wells(tubes, wells, updates)

        asset_group
          .assets
          .with_predicate('transferToTubeRackByPosition')
          .zip(wells)
          .each do |asset, well|
            if asset && well
              asset.facts.with_predicate('aliquotType').each { |f_aliquot| aliquot_types.push(f_aliquot.object) }

              updates.add(asset, 'transfer', well)
              updates.add(well, 'transferredFrom', asset)
              updates.merge(transfer_tubes(asset, well))
              updates.remove(asset.facts.with_predicate('transferToTubeRackByPosition'))
            end
          end
        if aliquot_types
          return updates unless validate_all_tubes_have_aliquot(tubes, updates)
          return updates unless validate_same_aliquot_between_tubes_and_destination_plate(tubes, rack, updates)

          if (aliquot_types.uniq.length == 1) && (aliquot_types.uniq.first == 'DNA')
            purpose_name = 'DNA Stock Plate'
          elsif (aliquot_types.uniq.length == 1) && (aliquot_types.uniq.first == 'RNA')
            purpose_name = 'RNA Stock Plate'
          else
            purpose_name = 'Stock Plate'
          end
          updates.add(rack, 'purpose', purpose_name)
        end
      end
    end
  end
end

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferTubesToTubeRackByPosition.new(asset_group: asset_group).process.to_json
