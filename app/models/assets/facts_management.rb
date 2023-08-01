module Assets::FactsManagement # rubocop:todo Style/Documentation
  def self.included(klass)
    klass.instance_eval do
      scope :with_fact, ->(predicate, object) { joins(:facts).where(facts: { predicate: predicate, object: object }) }
      scope :with_field, ->(predicate, object) { where(predicate => object) }

      scope :with_predicate, ->(predicate) { joins(:facts).where(facts: { predicate: predicate }) }
    end
  end

  def has_literal?(predicate, object)
    facts.any? { |f| f.predicate == predicate && f.object == object }
  end

  def has_predicate?(predicate)
    facts.any? { |f| f.predicate == predicate }
  end

  def has_predicate_with_value?(predicate)
    facts.any? { |f| (f.predicate == predicate) && !f.object.nil? }
  end

  def has_relation_with_value?(predicate)
    facts.any? { |f| (f.predicate == predicate) && !f.object_asset_id.nil? }
  end

  def has_fact?(fact)
    facts.any? do |f|
      if f.object.nil?
        (
          (fact.predicate == f.predicate) && (fact.object_asset == f.object_asset) && (fact.to_add_by == f.to_add_by) &&
            (fact.to_remove_by == f.to_remove_by)
        )
      else
        other_conds = true
        if fact.respond_to?(:to_add_by)
          other_conds = (fact.to_add_by == f.to_add_by) && (fact.to_remove_by == f.to_remove_by)
        end
        ((fact.predicate == f.predicate) && (fact.object == f.object) && other_conds)
      end
    end
  end

  def facts_to_s
    facts.each { |fact| render partial: fact }
  end

  def object_value(fact)
    fact.object_asset ? fact.object_asset.uuid : fact.object
  end

  def facts_for_reasoning
    [facts, Fact.as_object(asset)].flatten
  end

  def first_value_for(predicate)
    f = facts.with_predicate(predicate).first
    f&.object
  end

  def facts_with_triples(triples)
    uuid, predicate, object = triples
    if object.kind_of? String
      asset.facts.where(predicate: predicate, object: object)
    else
      asset.facts.where(predicate: predicate, object_asset: object)
    end
  end
end
