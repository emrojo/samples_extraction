# frozen_string_literal: true
class Pairing
  attr_reader :group, :step_type
  def initialize(params, step_type)
    @step_type = step_type
    @group = group_list(params)
  end

  def group_list(params)
    list = []
    params.each do |elem|
      l = []
      elem.each_pair do |c_id, barcode|
        l << {
          asset: Asset.find_by_barcode(barcode),
          condition_group: ConditionGroup.find_by_id(c_id)
        }
      end
      list << l
    end
    list
  end

  def assets
    @group.flatten.map { |g| g[:asset] }
  end

  def condition_groups
    @group.flatten.map { |g| g[:condition_group] }
  end

  def required_condition_groups_compatible?
    @group.all? do |list|
      cond_groups = list.map { |n| n[:condition_group] }
      (@step_type.condition_groups - cond_groups).empty?
    end
  end

  def group_compatible?
    @group.flatten.all? { |obj| obj[:condition_group].compatible_with?(obj[:asset]) }
  end

  def all_assets_exist?
    @group.flatten.map { |g| g[:asset] }.all?
  end

  def all_conditions_exist?
    @group.flatten.map { |g| g[:condition_group] }.all?
  end

  def step_type_compatible?
    @step_type.compatible_with?(assets)
  end

  def error_messages
    msgs = []
    msgs.push('Some barcodes were not found') unless all_assets_exist?
    msgs.push('Step requires more types of inputs to work') unless all_conditions_exist?
    msgs.push('Some assets are from a type different from the required') unless group_compatible?
    msgs.push('Assets are not passing the conditions for the step ') unless step_type_compatible?
    msgs.push('Step requires a different set of conditions') unless step_type_compatible?

    msgs.compact.join('. ')
  end

  def each_pair_assets
    @group.each do |list|
      asset_to_do = list.map { |n| n[:asset] }.compact
      yield asset_to_do if asset_to_do
    end
  end

  def valid?
    all_assets_exist? && all_conditions_exist? &&
      group_compatible? && step_type_compatible? && required_condition_groups_compatible?
  end
end
