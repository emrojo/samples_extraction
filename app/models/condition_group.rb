class ConditionGroup < ActiveRecord::Base
  belongs_to :step_type
  has_many :activity_types, :through => :step_type
  has_many :conditions, dependent: :destroy

  has_many :subject_actions, :class_name => 'Action', :foreign_key => 'subject_condition_group_id'
  has_many :object_actions, :class_name => 'Action', :foreign_key => 'object_condition_group_id'

  has_many :asset_groups

  scope :include_conditions, ->() { includes(:conditions) }

  def is_wildcard?
    conditions.empty?
  end

  def compatible_with?(assets, related_assets = [], checked_condition_groups=[], wildcard_values={})
    assets = [assets].flatten
    return true if is_wildcard?
    if ((cardinality) && (cardinality > 0))
      return false if assets.kind_of?(Array) && (assets.length > cardinality)
    end
    #return false if cardinality && (assets.length != cardinality)
    assets.all? do |asset|
      conditions.all? do |condition|
        condition.compatible_with?(asset, related_assets, checked_condition_groups, wildcard_values)
      end
    end
  end

  def has_runtime_conditions?
    runtime_conditions.count > 0
  end

  def runtime_conditions
    conditions.select{|c| c.is_runtime_evaluable_condition?}    
  end

  def runtime_conditions_compatible_with?(asset, related_asset)
    runtime_conditions.all? do |c|
      c.runtime_compatible_with?(asset,related_asset)
    end
  end

  def conditions_compatible_with?(assets, related_assets = [])
    [assets].flatten.all? do |asset|
      conditions.all? do |condition|
        condition.compatible_with?(asset, related_assets)
      end
    end
  end
end
