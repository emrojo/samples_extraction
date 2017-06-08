# frozen_string_literal: true
class KitType < ActiveRecord::Base
  belongs_to :activity_type

  scope :include_activity_types, ->() { includes(:activity_type) }
end
