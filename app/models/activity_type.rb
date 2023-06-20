class ActivityType < ApplicationRecord # rubocop:todo Style/Documentation
  has_many :activities
  has_many :kit_types
  has_many :activity_type_step_types
  has_many :step_types, through: :activity_type_step_types
  has_many :condition_groups, through: :step_types

  after_update :touch_activities

  has_and_belongs_to_many :instruments

  has_many :conditions, through: :condition_groups

  has_many :activity_type_compatibilities
  has_many :assets, -> { distinct }, through: :activity_type_compatibilities

  scope :alphabetical, -> { order(name: :asc) }

  include Deprecatable

  def touch_activities
    activities.each(&:touch)
  end

  attr_accessor :n3_definition

  def create_activity(params)
    activity = nil
    ActiveRecord::Base.transaction do
      group = AssetGroup.create
      activity =
        Activity.create({ kit: params[:kit], instrument: params[:instrument], activity_type: self, asset_group: group })
      activities << activity
      group.update!(activity_owner: activity)
    end
    activity
  end

  def available?
    superceded_by.nil?
  end

  def after_deprecate
    superceded_by.update(
      activities: superceded_by.activities | activities,
      kit_types: superceded_by.kit_types | kit_types,
      instruments: superceded_by.instruments | instruments
    )
    superceded_by.save!
  end

  def compatible_with?(assets)
    condition_groups.any? { |c| c.compatible_with?(assets) }
  end

  def to_n3
    render :n3
  end
end
