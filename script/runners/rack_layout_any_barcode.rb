# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/racking'

class RackLayoutAnyBarcode # rubocop:todo Style/Documentation
  attr_reader :asset_group

  include Actions::Racking

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def assets_compatible_with_step_type
    asset_group.uploaded_files
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        updates.merge(rack_layout_any_barcode)
        updates.remove_assets([[asset_group.uploaded_files.first.asset.uuid]])
      end
    end
  end
end

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)

begin
  updates = RackLayoutAnyBarcode.new(asset_group: asset_group).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue InvalidDataParams => e
  puts({ set_errors: e.errors }.to_json)
rescue StandardError => e
  puts({ set_errors: ['Unknown error while parsing file' + e.to_json + e.backtrace.join] }.to_json)
end
