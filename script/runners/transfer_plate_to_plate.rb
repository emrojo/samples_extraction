# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/plate_transfer'

# Stamps an Asset (plate or tube rack) to another Asset
#  In the step type config, there should be:
# A condition group, with name set (e.g. 'p')
# A new asset, with addFacts 'transferredFrom:p', where 'p' is the name of above group
# The new asset should also have the type specified, by adding fact 'a:Plate' or 'a:TubeRack'
# If the new asset is destined for export for Sequencescape...
# ...add fact 'barcodeType:NoBarcode', and Samples Extraction won't create a barcode
class TransferPlateToPlate
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  # rubocop:todo Naming/MethodName
  def _CODE; end

  # rubocop:enable Naming/MethodName

  #
  #  {
  #    ?p :a :Plate .
  #    ?q :a :Plate .
  #    ?p :transfer ?q .
  #    ?p :contains ?tube .
  #   }
  #    =>
  #   {
  #    ?q :contains ?tube .
  #   } .
  #

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transferredFrom').count > 0
  end

  def process
    FactChanges.new.tap do |updates|
      aliquot_types = []
      if assets_compatible_with_step_type
        plates =
          asset_group
            .assets
            .with_predicate('transferredFrom')
            .each do |plate|
              plate
                .facts
                .with_predicate('transferredFrom')
                .each do |f|
                  source = f.object_asset
                  Actions::PlateTransfer.transfer_plates(source, plate, updates)
                end
            end
      end
    end
  end
end
return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferPlateToPlate.new(asset_group: asset_group).process.to_json
