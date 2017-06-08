# frozen_string_literal: true
class ActivityTypeCompatibility < ActiveRecord::Base
  belongs_to :activity_type
  belongs_to :asset
end
