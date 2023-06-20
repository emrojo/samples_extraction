# A record that represents a step type belonging to an activity type.
# Step types can belong to many activity types at the same time.
# (many to many relation)
class ActivityTypeStepType < ApplicationRecord
  belongs_to :activity_type
  belongs_to :step_type
end
