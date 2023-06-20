# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
matches = args.match(/(\d*)\.json/)
asset_group_id = matches[1]

args2 = ARGV[1]
matches2 = args2.match(/(\d*)\.json/)
step_id = matches2[1]
asset_group = AssetGroup.find(asset_group_id)
step = Step.find(step_id)

updates = FactChanges.new

require "#{Rails.root}/script/runners/transfer_plate_to_plate"

updates.parse_json(TransferPlateToPlate.new(asset_group: asset_group).process.to_json)
updates.apply(step)

require "#{Rails.root}/script/runners/update_sequencescape"

puts UpdateSequencescape.new(asset_group: asset_group, step: step).process.to_json
