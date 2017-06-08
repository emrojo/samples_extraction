class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true
  belongs_to :object_asset, :class_name => 'Asset'

  scope :not_to_remove, ->() { where(:to_remove_by => nil) }

  scope :with_predicate, ->(predicate) { where(:predicate => predicate)}

  scope :with_ns_predicate, ->(namespace) { where(:ns_predicate => namespace)}

  scope :with_fact, -> (predicate, object) { where(:predicate => predicate, :object => object)}

  scope :include_object_asset, ->() {includes(:object_asset)}

  #scope :with_namespace, ->(namespace) { where("predicate LIKE :namespace", namespace: "#{namespace}\#%")}

  #scope :for_sequencescape, ->() { with_namespace('SS') }

  def set_to_remove_by(step)
    update_attributes!(:to_remove_by => step)
  end

  def set_to_add_by(step)
    update_attributes!(:to_add_by => step)
  end

  def object_value
    literal? ? object : Asset.find(object_asset_id)
  end

  def object_label
    return object unless object_asset
    "#{object_asset.asset_description} #{object_asset.barcode.blank? ? '#' : Asset.find(object_asset_id).barcode}"
  end

  def canonical_comparison_for_sorting(f2)
    f1 = self
    if f1.predicate == f2.predicate
      obj1 = f1.object || '?'
      obj1 =  '?' unless f1["object_asset_id"].nil?
      obj2 = f1.object || '?'
      obj2 =  '?' unless f2["object_asset_id"].nil?
      (obj1 <=> obj2)
    else
      f1.predicate <=> f2.predicate
    end
  end

end

