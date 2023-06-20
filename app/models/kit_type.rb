# A kit type is a group of kits and is linked with onluy one activity type
# Using a kit from a kit type will mean start using the activity type associated
# (as long as the instrument supports the activity type requested)
class KitType < ApplicationRecord
  belongs_to :activity_type
  has_many :kits
end
