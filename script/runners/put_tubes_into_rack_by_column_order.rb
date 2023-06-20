# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/racking'
require 'token_util'
include Actions::Racking

return unless ARGV.any? { |s| s.match('.json') }

updates = FactChanges.new

args = ARGV[0]
out({}) unless args
matches = args.match(/(\d*)\.json/)
out({}) unless matches
asset_group_id = matches[1]
asset_group = AssetGroup.find(asset_group_id)
rack = asset_group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'TubeRack' }).first
tube_ids_in_rack = rack.facts.with_predicate('contains').map(&:object_asset_id)
locations_with_tube = Fact.where(predicate: 'location', asset_id: tube_ids_in_rack).map(&:object)

tubes = asset_group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'Tube' })

LETTERS = ('A'..'H').to_a
COLUMNS = (1..12).to_a
POSITIONS = TokenUtil.generate_positions(LETTERS, COLUMNS)

available_locations = POSITIONS - locations_with_tube

if available_locations.length < tubes.length
  updates.set_errors(['There are not enough locations available for the tubes'])
else
  layout =
    tubes
      .each_with_index
      .reduce([]) do |memo, list|
        tube = list[0]
        idx = list[1]
        location = available_locations[idx]
        memo.push(asset: tube, location: available_locations[idx])
      end
  updates.add(rack, 'layout', 'Complete')
  updates.merge(Actions::Racking.reracking_tubes(rack, layout))
end

puts updates.to_json
