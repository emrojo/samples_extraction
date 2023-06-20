class Instrument < ApplicationRecord # rubocop:todo Style/Documentation
  has_and_belongs_to_many :activity_types
  has_many :activities

  def compatible_with_kit?(kit)
    [kit, kit.kit_type, kit.kit_type.activity_type, activity_types.include?(kit.kit_type.activity_type)].all?
  end
end
