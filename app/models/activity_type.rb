class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :kit_types
  has_many :condition_groups, :through => :step_types
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_and_belongs_to_many :instruments

  has_many :conditions, :through => :condition_groups

  has_many :activity_type_compatibilities
  has_many :assets, :through => :activity_type_compatibilities

  include Deprecatable


  before_update :parse_n3

  attr_accessor :n3_definition

  def parse_n3
    return
    unless n3_definition.nil?
      SupportN3::parse_string(n3_definition, {})
    end
  end

  def after_deprecate
    superceded_by.update_attributes(
      activities: superceded_by.activities | activities,
      kit_types:  superceded_by.kit_types | kit_types, 
      instruments: superceded_by.instruments | instruments
      )
    superceded_by.save!
  end

  # def render(sel)
  #   view = ActionView::Base.new(ActionController::Base.view_paths, activity_type: self)
  #   view.extend ApplicationHelper
  #   view.class.cattr_accessor :activity_type
  #   view.activity_type = self
  #   view.render(:partial => 'activity_types/activity_type', formats: [:n3])
  # end


  # def after_deprecate
  #   self.reload
  #   main_instance = self.superceded_by
  #   main_instance.supercedes.each do |activity_type|
  #     activity_type.kit_types.each do |kit_type|
  #       kit_type.update_attributes!(:activity_type => main_instance)
  #     end
  #     activities.each do |activity|
  #       activity.update_attributes!(:activity_type => main_instance)
  #     end
  #   end
  # end

  def compatible_with?(assets)
    condition_groups.any?{|c| c.compatible_with?(assets)}
  end

  def to_n3
    render :n3
  end
end
