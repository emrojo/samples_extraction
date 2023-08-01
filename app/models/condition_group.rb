class ConditionGroup < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :step_type
  has_many :activity_types, through: :step_type
  has_many :conditions, dependent: :destroy
  has_many :subject_actions, class_name: 'Action', foreign_key: 'subject_condition_group_id'
  has_many :object_actions, class_name: 'Action', foreign_key: 'object_condition_group_id'
  has_many :asset_groups

  def is_wildcard?
    conditions.empty?
  end

  def select_compatible_assets(assets, position = nil)
    compatibles = assets.select { |a| compatible_with?(a) }
    (position.nil? ? compatibles : [compatibles[position]])
  end

  def compatible_with?(assets, related_assets = [], checked_condition_groups = [], wildcard_values = {})
    assets = [assets].flatten
    return true if is_wildcard?

    if (cardinality) && (cardinality > 0)
      return false if assets.kind_of?(Array) && (assets.length > cardinality)
    end
    assets.all? do |asset|
      conditions.all? do |condition|
        condition.compatible_with?(asset, related_assets, checked_condition_groups, wildcard_values)
      end
    end
  end

  def conditions_compatible_with?(assets, related_assets = [])
    [assets].flatten.all? { |asset| conditions.all? { |condition| condition.compatible_with?(asset, related_assets) } }
  end
end
