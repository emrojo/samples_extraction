class ContainerInferences # rubocop:todo Style/Documentation
  attr_reader :asset_group

  def initialize(params)
    @asset_group = params[:asset_group]
  end

  def containers
    asset_group.assets.joins(<<~SQL.squish).uniq
      INNER JOIN facts as plate_facts on plate_facts.asset_id=assets.id AND plate_facts.predicate='contains'
      INNER JOIN assets as tubes on tubes.id=plate_facts.object_asset_id
      INNER JOIN facts as tubes_facts on tubes_facts.asset_id=tubes.id AND (tubes_facts.predicate='aliquotType' OR tubes_facts.predicate='study_name')
    SQL
  end

  def purpose_for_aliquot(aliquot)
    return 'DNA Stock Plate' if aliquot == 'DNA'
    return 'RNA Stock Plate' if aliquot == 'RNA'

    return 'Stock Plate'
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

  def purpose_for(asset)
    list =
      asset
        .facts
        .with_predicate('contains')
        .map { |f| f.object_asset.facts.with_predicate('aliquotType').map(&:object) }
        .flatten
        .compact
        .uniq
    return '' if list.count > 1

    return purpose_for_aliquot(list.first)
  end

  def process
    FactChanges.new.tap do |updates|
      if containers.count > 0
        containers.each do |asset|
          updates.add(asset, 'study_name', study_name_for(asset))
          updates.add(asset, 'purpose', purpose_for(asset))
        end
      end
    end
  end
end

def out(val)
  puts val.to_json
  return
end

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
out({}) unless args
matches = args.match(/(\d*)\.json/)
out({}) unless matches
asset_group_id = matches[1]
asset_group = AssetGroup.find(asset_group_id)
out(ContainerInferences.new(asset_group: asset_group).process)
