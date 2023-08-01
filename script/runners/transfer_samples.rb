# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/tube_transfer'

class TransferSamples # rubocop:todo Style/Documentation
  include Actions::TubeTransfer

  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def assets_compatible_with_step_type
    (asset_group.assets.with_predicate('transferredFrom').count > 0) ||
      (asset_group.assets.with_predicate('transfer').count > 0)
  end

  def asset_group_for_execution
    asset_group
  end

  def each_asset_and_modified_asset
    asset_group
      .assets
      .with_predicate('transfer')
      .each do |asset|
        asset
          .facts
          .with_predicate('transfer')
          .each do |fact|
            modified_asset = fact.object_asset
            yield(asset, modified_asset) if asset && modified_asset
          end
      end
    asset_group
      .assets
      .with_predicate('transferredFrom')
      .each do |modified_asset|
        modified_asset
          .facts
          .with_predicate('transferredFrom')
          .each do |fact|
            asset = fact.object_asset
            yield(asset, modified_asset) if asset && modified_asset
          end
      end
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        each_asset_and_modified_asset do |asset, modified_asset|
          updates.add(modified_asset, 'is', 'Used')
          updates.add(modified_asset, 'transferredFrom', asset)

          updates.merge(transfer_tubes(asset, modified_asset))
        end
      end
    end
  end
end
return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts TransferSamples.new(asset_group: asset_group).process.to_json
