class Condition < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :condition_group
  has_many :activity_types, through: :condition_group
  belongs_to :object_condition_group, class_name: 'ConditionGroup'

  def check_wildcard_condition(asset, wildcard_values = {})
    cg = object_condition_group

    # If the condition group is a wildcard, we'll cache all the possible
    # values and check compatibility with other definitions of the same
    # wildcard.
    if asset.facts.kind_of? Array
      facts = asset.facts.select { |f| f.predicate == predicate }
    else
      facts = asset.facts.with_predicate(predicate)
    end
    return false if facts.count == 0

    return false unless facts.first.respond_to?(:object_value)

    actual_values = facts.map(&:object_value)

    store_wildcard_values(wildcard_values, cg, asset, actual_values)

    return !wildcard_values[cg.id][asset.id].empty?
  end

  def store_wildcard_values(wildcard_values, cg, asset, actual_values)
    wildcard_values[cg.id] = {} unless wildcard_values[cg.id]
    if wildcard_values[cg.id][asset.id]
      wildcard_values[cg.id][asset.id] &= actual_values
    else
      wildcard_values[cg.id][asset.id] = actual_values
    end
  end

  def check_related_condition_group(cg, fact, related_assets = [], checked_condition_groups = [], wildcard_values = {})
    related_asset = fact.object_asset

    # This condition does not support evaluating relations like:
    # ?a :t ?b . ?b :t ?c . ?c :t ?a .
    # because it end up in a loop (SystemStackError). To fix this, from ConditionGroup
    # we would need to pass as an argument the list of condition_groups valid up to
    # this point, in which the only thing we need to validate is the object in the relations.
    # For the moment these types of relations will remain unsupported
    compatible =
      if checked_condition_groups.include?(cg)
        fact.predicate == predicate
      else
        checked_condition_groups << cg
        (fact.predicate == predicate) &&
          cg.compatible_with?(related_asset, related_assets, checked_condition_groups, wildcard_values)
      end
    related_assets.push(related_asset) if compatible
    compatible
  end

  def is_wildcard_condition?
    return object_condition_group && object_condition_group.is_wildcard?
  end

  def runtime_compatible_with?(asset, related_asset)
    return asset == related_asset if predicate == 'equalTo'
    return asset != related_asset if predicate == 'notEqualTo'
    return asset.facts.with_predicate(object).count == 0 if predicate == 'hasNotPredicate'
    return asset.facts.with_predicate(object).count == 0 if predicate == 'sum'
  end

  def is_runtime_evaluable_condition?
    (predicate == 'equalTo') || (predicate == 'notEqualTo') || (predicate == 'hasNotPredicate') || (predicate == 'sum')
  end

  def compatible_with?(asset, related_assets = [], checked_condition_groups = [], wildcard_values = {})
    return true if is_runtime_evaluable_condition?
    return false if asset.nil?
    return check_wildcard_condition(asset, wildcard_values) if is_wildcard_condition?

    asset.facts.any? do |fact|
      # Either objects are equal, or both of them are relations to something. We
      # do not check the relations values, because we consider them as wildcards
      if object_condition_group_id.nil? || (fact.respond_to?(:object_asset_id) && fact.object_asset_id.nil?)
        ((fact.predicate == predicate) && (fact.object == object))
      else
        check_related_condition_group(
          object_condition_group,
          fact,
          related_assets,
          checked_condition_groups,
          wildcard_values
        )
      end
    end
  end
end
