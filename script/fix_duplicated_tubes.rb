group = AssetGroup.find(26_968)

rack = group.assets.joins(:facts).where(facts: { predicate: 'a', object: 'TubeRack' }).first

facts = rack.facts.with_predicate('contains')

duplicateds =
  facts.reduce({}) do |memo, fact|
    if fact.predicate == 'contains'
      memo[fact.object_asset_id] = [] unless memo[fact.object_asset_id]
      memo[fact.object_asset_id].push(fact)
    end
    memo
  end

duplicateds2 = duplicateds.map { |_key, values| values[1] }
