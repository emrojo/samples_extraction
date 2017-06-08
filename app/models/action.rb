# frozen_string_literal: true
class Action < ActiveRecord::Base
  belongs_to :subject_condition_group, class_name: 'ConditionGroup'
  belongs_to :object_condition_group, class_name: 'ConditionGroup'

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  scope :include_subject_condition_group, ->() { includes(:subject_condition_group) }
  scope :include_object_condition_groups, ->() { includes(:include_object_condition_groups) }

  def self.types
    @@TYPES
  end
end
