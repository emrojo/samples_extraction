# A Fact stores information about an {Asset}
class Fact < ApplicationRecord
  belongs_to :asset, counter_cache: true
  belongs_to :object_asset, class_name: 'Asset'

  scope :not_to_remove, -> { where(to_remove_by: nil) }
  scope :with_predicate, ->(predicate) { where(predicate: predicate) }
  scope :with_ns_predicate, ->(namespace) { where(ns_predicate: namespace) }
  scope :with_fact, ->(predicate, object) { where(predicate: predicate, object: object) }
  scope :from_remote_asset, -> { where(is_remote?: true) }
  scope :created_before, ->(date) { date.nil? ? all : where('created_at < ?', date) }

  # Confirm test coverage before correcting this one, as its unclear how optional presence validation
  # plays with belongs_to_required_by_default.
  validates :object_asset_id, presence: true, unless: :literal? # rubocop:todo Rails/RedundantPresenceValidationOnBelongsTo
  validates :object_asset_id, presence: false, if: :literal?

  def set_to_remove_by(step)
    update!(to_remove_by: step)
  end

  def set_to_add_by(step)
    update!(to_add_by: step)
  end

  def object_value
    literal? ? object : object_asset
  end

  def object_value_or_uuid
    literal? ? object : object_asset.uuid
  end

  def object_label
    return object unless object_asset
  end

  def canonical_comparison_for_sorting(f2)
    f1 = self
    if f1.predicate == f2.predicate
      obj1 = f1.object || '?'
      obj1 = '?' unless f1['object_asset_id'].nil?
      obj2 = f1.object || '?'
      obj2 = '?' unless f2['object_asset_id'].nil?
      (obj1 <=> obj2)
    else
      f1.predicate <=> f2.predicate
    end
  end
end
