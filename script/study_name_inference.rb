class StudyNameInference # rubocop:todo Style/Documentation
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  # rubocop:todo Naming/MethodName
  def _CODE
    '
      {
        ?asset :contains ?anotherAsset .
        ?anotherAsset :study_name ?study .
      }=>{
        :step :addFacts { ?asset :study_name ?study . } .
      }.
    '
  end

  # rubocop:enable Naming/MethodName

  def assets_compatible_with_step_type
    asset_group
      .assets
      .with_predicate('contains')
      .select { |a| a.facts.with_predicate('contains').any? { |f| f.object_asset.has_predicate?('study_name') } }
  end

  def study_name_for(asset)
    list =
      asset
        .facts
        .with_predicate('contains')
        .map { |f| f.object_asset.facts.with_predicate('study_name').map(&:object) }
        .flatten
        .compact
        .uniq
    return '' if list.count > 1

    return list.first
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each { |asset| updates.add(asset, 'study_name', study_name_for(asset)) }
      end
    end
  end
end
return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts StudyNameInference.new(asset_group: asset_group).process.to_json
