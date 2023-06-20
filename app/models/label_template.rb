# frozen_string_literal: true

class LabelTemplate < ApplicationRecord # rubocop:todo Style/Documentation
  CLASS_TYPE_TEMPLATE_ALIASES = { 'TubeRack' => 'Plate', 'SampleTube' => 'Tube' }.freeze

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  # This is pretty low priority, as this table is very low volume and throughput
  # We're due to drop the external_id column following completing the migration
  # to the V2 api, so can add the constraints then
  validates :name, :external_id, presence: true, uniqueness: true

  # rubocop:enable Rails/UniqueValidationWithoutIndex

  # We used to have the ability to have several templates per template type,
  # which would resolve based on the barcode type. However in practice these
  # were always resolving to the same two templates. I've simplified the code
  # and added this validation to highlight any violations of this assumption in
  # future
  validates :template_type, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex

  # Currently all label templates actively used by Sample Extraction use the
  # label name 'label', so it has been set here. If this changes in future
  # we can add a column to the database and this will be handled correctly
  attribute :label_name, default: 'label'

  def self.for_type(class_type)
    type = CLASS_TYPE_TEMPLATE_ALIASES.fetch(class_type, class_type)

    find_by(template_type: type) ||
      raise(
        "Could not find any label template for type '#{type}'. " \
          'Please contact LIMS support to fix the problem'
      )
  end
end
