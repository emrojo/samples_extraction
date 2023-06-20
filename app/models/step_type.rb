require 'support_n3'

class StepType < ApplicationRecord # rubocop:todo Style/Documentation
  before_update :remove_previous_conditions
  after_save :create_next_conditions # , :unless => :for_reasoning?

  after_update :touch_activities

  has_many :activity_type_step_types, dependent: :destroy
  has_many :activity_types, through: :activity_type_step_types
  has_many :activities, -> { distinct }, through: :activity_types
  has_many :condition_groups, dependent: :destroy
  has_many :actions, dependent: :destroy

  has_many :action_subject_condition_groups, -> { distinct }, through: :actions, source: :subject_condition_group
  has_many :action_object_condition_groups, -> { distinct }, through: :actions, source: :object_condition_group
  def action_condition_groups
    [action_subject_condition_groups, action_object_condition_groups].flatten.uniq - condition_groups
  end

  include Deprecatable

  scope :with_template, -> { where('step_template is not null') }

  def self.for_task_type(task_type)
    select { |stype| stype.task_type == task_type }
  end

  scope :for_reasoning, -> { not_deprecated.where(for_reasoning: true).order(priority: :desc) }

  scope :not_for_reasoning, -> { not_deprecated.where(for_reasoning: false) }

  def touch_activities
    activities.each { |activity| activity.touch if activity.is_being_listened? }
  end

  def after_deprecate
    superceded_by.activity_types << activity_types
    update!(activity_types: [])
  end

  def all_step_templates
    return '', 'upload_file'
  end

  def valid_name_file(names)
    names.select { |l| l.match(/^[A-Za-z]/) }
  end

  def all_background_steps_files
    valid_name_file(Dir.entries('lib/background_steps'))
  rescue Errno::ENOENT => e
    []
  end

  def all_inferences_files
    valid_name_file(Dir.entries('script/inferences'))
  rescue Errno::ENOENT => e
    []
  end

  def all_runners_files
    valid_name_file(Dir.entries('script/runners'))
  rescue Errno::ENOENT => e
    []
  end

  def all_step_actions
    [
      # all_background_steps_files,
      all_inferences_files,
      all_runners_files
    ].flatten
  end

  def task_type
    return 'background_step' if (actions.count > 0) || step_action.nil?
    return 'cwm' if step_action&.end_with?('.n3')

    return 'runner'
  end

  def class_for_task_type
    if task_type == 'cwm'
      Steps::BackgroundTasks::Inference
    elsif task_type == 'runner'
      Steps::BackgroundTasks::Runner
    else
      Step
    end
  end

  def create_next_conditions
    SupportN3.parse_string(n3_definition, {}, self) unless n3_definition.nil?
  end

  def remove_previous_conditions
    condition_groups.each do |condition_group|
      condition_group.conditions.each(&:destroy)
      condition_group.destroy
    end
    actions.each { |action| action.update(step_type_id: nil) }
  end

  def condition_group_classification_for(assets, checked_condition_groups = [], wildcard_values = {})
    related_assets = []
    h = assets.index_with { |asset| condition_groups_for(asset, related_assets, [], wildcard_values) }
    related_assets.each { |a| h[a] = condition_groups_for(a, [], checked_condition_groups, wildcard_values) }
    h
  end

  def every_condition_group_satisfies_cardinality(classification)
    # http://stackoverflow.com/questions/10989259/swapping-keys-and-values-in-a-hash
    inverter_classification = classification.each_with_object({}) { |(k, v), o| v.each { |cg| (o[cg] ||= []) << k } }
    inverter_classification.keys.all? do |condition_group|
      condition_group.cardinality.nil? || (condition_group.cardinality == 0) ||
        (condition_group.cardinality >= inverter_classification[condition_group].length)
    end
  end

  def every_condition_group_has_at_least_one_asset?(classification, cgroups = nil)
    cgroups = condition_groups if cgroups.nil?
    (classification.values.flatten.uniq.length == cgroups.length)
  end

  def every_asset_has_at_least_one_condition_group?(classification)
    (classification.values.all? { |condition_group| ([condition_group].flatten.length >= 1) })
  end

  def every_required_asset_is_in_classification?(classification, required_assets)
    return true if required_assets.nil?

    required_assets.all? { |asset| !classification[asset].empty? }
  end

  def compatible_with?(assets, required_assets = nil, checked_condition_groups = [], wildcard_values = {})
    assets = Array(assets).flatten

    # Every asset has at least one condition group satisfied
    classification = condition_group_classification_for(assets, checked_condition_groups, wildcard_values)

    every_condition_group_satisfies_cardinality(classification) &&
      every_condition_group_has_at_least_one_asset?(classification) &&
      every_asset_has_at_least_one_condition_group?(classification) &&
      every_required_asset_is_in_classification?(classification, required_assets)
  end

  def condition_groups_for(asset, related_assets = [], checked_condition_groups = [], wildcard_values = {})
    condition_groups.select do |condition_group|
      condition_group.compatible_with?([asset].flatten, related_assets, checked_condition_groups, wildcard_values)
      # condition_group.conditions_compatible_with?(asset, related_assets)
    end
  end

  def classification_for(assets, cgroups)
    assets.reduce({}) do |memo, asset|
      memo[asset] = cgroups.select { |condition_group| condition_group.compatible_with?([asset].flatten) }
      memo
    end
  end

  def to_n3
    render :n3
  end
end
