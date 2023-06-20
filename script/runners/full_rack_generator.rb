# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
out({}) unless args
matches = args.match(/(\d*)\.json/)
out({}) unless matches
asset_group_id = matches[1]
asset_group = AssetGroup.find(asset_group_id)
rack = asset_group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'TubeRack' }).first

current_tubes = rack.facts.where(predicate: 'contains').map(&:object_asset)
facts_from_tubes = current_tubes.pluck(:facts)
locations_with_tube = facts_from_tubes.empty? ? [] : facts_from_tubes.where(predicate: 'location').pluck(:object)

tubes = Array.new(96) { |i| "?tube#{i}" }
letters = ('A'..'H').to_a
columns = (1..12).to_a
location_for_position = Array.new(96) { |i| "#{letters[(i / columns.length).floor]}#{columns[i % columns.length]}" }

facts_to_add =
  (location_for_position - locations_with_tube).reduce([]) do |memo, location|
    tube_for_location = tubes[location_for_position.index(location)]
    memo.push([rack.uuid, 'contains', tube_for_location])
    memo.push([tube_for_location, 'location', location])
  end

obj = { create_assets: tubes, add_facts: facts_to_add }

puts obj.to_json
