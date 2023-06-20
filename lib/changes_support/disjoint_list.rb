module ChangesSupport # rubocop:todo Style/Documentation
end

class ChangesSupport::DisjointList # rubocop:todo Style/Documentation
  SEED_FOR_UNIQUE_IDS = Random.rand(1000)
  MAX_DEEP_UNIQUE_ID = 3

  include Enumerable

  attr_accessor :location_for_unique_id, :disjoint_lists, :list
  attr_reader :name

  DISABLED_NAME = 'DISABLED'

  delegate :each, :length, :[], :flatten, :uniq!, to: :list

  def initialize(list)
    @name = "object_id_#{object_id}"

    @location_for_unique_id = {}

    @list = []
    @disjoint_lists = [self]
    list.each { |o| add(o) }
  end

  def add_disjoint_list(disjoint_list)
    disjoints = (disjoint_list.disjoint_lists - disjoint_lists)
    disjoint_lists.concat(disjoints).uniq

    disjoints.each do |disjoint|
      _synchronize_with_list(disjoint)

      disjoint.location_for_unique_id = location_for_unique_id
      disjoint.disjoint_lists = disjoint_lists
    end
  end

  def store_for(element)
    _store_for(unique_id_for_element(element))
  end

  def _store_for(unique_id)
    store_name = location_for_unique_id[unique_id]
    return nil if store_name.nil? || store_name == DISABLED_NAME

    @disjoint_lists.find { |l| l.name == store_name }
  end

  def enabled?(element)
    !store_for(element).nil?
  end

  def disabled?(element)
    disabled_key?(unique_id_for_element(element))
  end

  def disabled_key?(key)
    @location_for_unique_id[key] == DISABLED_NAME
  end

  def enabled_in_other_list?(element)
    enabled?(element) && !include?(element)
  end

  def include?(element)
    include_key?(unique_id_for_element(element))
  end

  def include_key?(key)
    @location_for_unique_id[key] == name
  end

  def remove(element)
    unique_id = unique_id_for_element(element)
    remove_from_raw_list_by_id(unique_id)
    @location_for_unique_id.delete(unique_id)
  end

  def remove_from_raw_list_by_id(unique_id)
    @list.delete_if { |a| unique_id_for_element(a) == unique_id }
  end

  def <<(element)
    element.kind_of?(Array) ? element.each { |e| add(e) } : add(element)
  end

  def concat(element)
    element.kind_of?(Array) ? element.each { |e| add(e) } : add(element)
  end

  def push(element)
    add(element)
  end

  def add(element)
    return concat_disjoint_list(element) if element.kind_of?(ChangesSupport::DisjointList)

    if enabled_in_other_list?(element)
      disable(element)
    elsif include?(element)
      # It is already in our list, so we do not add it again
      return false
    else
      enable(element)
    end
    self
  end

  def sum_function_for(value)
    value.hash
  end

  def unique_id_for_element(element)
    _unique_id_for_element(element, 0)
  end

  def concat_disjoint_list(disjoint_list)
    disjoint_list.location_for_unique_id.keys.each { |key| _disable(key) if disjoint_list.disabled_key?(key) }
    disjoint_list.to_a.each { |val| add(val) }
    self
  end

  def merge(disjoint_list)
    disjoint_list.location_for_unique_id.keys.each do |key|
      _disable(key) if !disjoint_list.include_key?(key) || disjoint_list.disabled_key?(key)
    end
    disjoint_list.to_a.each { |val| add(val) }
    self
  end

  def enable(element)
    return if disabled?(element)

    unique_id = unique_id_for_element(element)

    # Is not in any of the lists so we can add it
    (element.kind_of?(Enumerable) && (!element.kind_of?(Hash))) ? @list.concat(element) : @list.push(element)
    @location_for_unique_id[unique_id] = name
  end

  def disable(element)
    _disable(unique_id_for_element(element))
  end

  protected

  def _synchronize_with_list(disjoint_list)
    disjoint_list.location_for_unique_id.keys.each do |key|
      unless location_for_unique_id[key] == DISABLED_NAME
        # If my disjoint lists do not have the element
        if location_for_unique_id[key].nil?
          location_for_unique_id[key] = disjoint_list.location_for_unique_id[key]
          _disable(key) if location_for_unique_id[key] == DISABLED_NAME
        else
          # If my lists have the element alredy
          _disable(key) if location_for_unique_id[key] != disjoint_list.location_for_unique_id[key]
        end
      end
    end
  end

  def _disable(unique_id)
    store = _store_for(unique_id)
    store.remove_from_raw_list_by_id(unique_id) if store
    location_for_unique_id[unique_id] = DISABLED_NAME
  end

  def _unique_id_for_element(element, deep = 0)
    return sum_function_for(SecureRandom.uuid) if deep == MAX_DEEP_UNIQUE_ID

    if element.kind_of?(String)
      sum_function_for(element)
    elsif element.try(:uuid)
      sum_function_for(element.uuid)
    elsif element.try(:id)
      sum_function_for("#{element.class}_#{element.id}")
    elsif element.kind_of?(Hash)
      if element.has_key?(:uuid) && (!element[:uuid].nil?)
        sum_function_for(element[:uuid])
      elsif element.has_key?(:predicate)
        _unique_id_for_fact(element)
      else
        sum_function_for(
          element.keys.dup.concat(element.values.map { |val| _unique_id_for_element(val, deep + 1) }).join
        )
      end
    elsif element.kind_of?(Enumerable)
      sum_function_for(element.map { |o| _unique_id_for_element(o, deep + 1) }.join)
    else
      sum_function_for(element.to_s)
    end
  end

  def _unique_id_for_fact(element)
    sum_function_for(
      [
        (element[:asset_id] || element[:asset].id || element[:asset].object_id),
        element[:predicate],
        (element[:object] || element[:object_asset_id] || element[:object_asset].id || element[:object_asset].object_id)
      ].join('_')
    )
  end
end
