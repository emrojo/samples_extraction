# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'actions/racking'
require 'parsers/csv_metadata/csv_parser'

class LoadMetadata # rubocop:todo Style/Documentation
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def assets_compatible_with_step_type
    asset_group.uploaded_files
  end

  def find_asset(line_parsed)
    if line_parsed['location']
      parent = Asset.find_by!(barcode: line_parsed['barcode'])
      facts =
        parent.facts.where(
          predicate: 'contains',
          object_asset_id: Fact.where(predicate: 'location', object: line_parsed['location']).select(:asset_id)
        )
      raise 'More than one asset found' if facts.count > 1

      return facts.first.object_asset
    else
      Asset.find_by!(barcode: line_parsed['barcode'])
    end
  end

  def filter_unneeded_data(line_parsed)
    line_parsed.reject { |k, _v| k == 'location' || k == 'barcode' }
  end

  def metadata_updates(asset_group)
    FactChanges.new.tap do |updates|
      content = asset_group.uploaded_files.first.data
      parser = Parsers::CsvMetadata::CsvParser.new(content)
      if parser.valid?
        parser.data.each do |line_parsed|
          asset = find_asset(line_parsed)
          data = filter_unneeded_data(line_parsed)
          data.keys.each do |key|
            updates.remove(asset.facts.with_predicate(key))
            updates.add(asset, key, data[key])
          end
        end
      end
    end
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        updates.merge(metadata_updates(@asset_group))
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
  updates = LoadMetadata.new(asset_group: asset_group).process
  json = updates.to_json
  JSON.parse(json)
  puts json
rescue InvalidDataParams => e
  puts({ set_errors: e.errors }.to_json)
rescue StandardError => e
  puts({ set_errors: ['Unknown error while parsing file' + e.backtrace.to_s] }.to_json)
end
