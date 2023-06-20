# ActiveRecord class to represent when a labware is compatible with an
# activity type
class ActivityTypeCompatibility < ApplicationRecord
  belongs_to :activity_type
  belongs_to :asset
end
