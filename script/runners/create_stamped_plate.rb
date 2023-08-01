# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/plate_transfer'

class CreateStampedPlate # rubocop:todo Style/Documentation
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def source_plate
    asset_group.assets.first
  end

  def assets_compatible_with_step_type
    ((asset_group.assets.count == 1) && (source_plate.kind_of_plate?))
  end

  def process
    FactChanges.new.tap do |updates|
      updates.create_assets(['?stampedPlate'])
      updates.add('?stampedPlate', 'a', 'Plate')
      updates.add('?stampedPlate', 'transferredFrom', source_plate.uuid)
      updates.add(source_plate.uuid, 'transfer', '?stampedPlate')
      updates.remove_assets([[source_plate.uuid]])
      updates.add_assets([['?stampedPlate']])
      Actions::PlateTransfer.transfer_plates(source_plate, '?stampedPlate', updates)
    end
  end
end

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts CreateStampedPlate.new(asset_group: asset_group).process.to_json
