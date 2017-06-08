# frozen_string_literal: true
module Deprecatable
  extend ActiveSupport::Concern
  included do
    has_many   :supercedes,    class_name: name, foreign_key: :superceded_by_id
    belongs_to :superceded_by, class_name: name, foreign_key: :superceded_by_id

    scope :visible, -> { where(superceded_by_id: nil) }
    scope :not_deprecated, -> { where(superceded_by_id: nil) }
  end

  def deprecated?
    !superceded_by.nil?
  end

  def deprecate_with(instance)
    update_attributes!(superceded_by: instance)
    after_deprecate
  end
end
