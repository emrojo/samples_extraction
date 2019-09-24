module Assets::Fields

  PRIORITIZED_ASSET_TYPES = ["TubeRack", "Plate", "Tube", "SampleTube"]

  def asset_type
    PRIORITIZED_ASSET_TYPES.each do |asset_type|
      return asset_type if asset_types.include?(asset_type)
    end
    return asset_types.first if asset_types.count > 0
    return nil
  end

  def asset_types
    facts.select{|f| f[:predicate] == 'a'}.map(&:object)
  end

  def wells
    facts.with_predicate('contains').map(&:object_asset)
  end

  def short_description
    "#{aliquot_type} #{asset_type} #{barcode.blank? ? '#' : barcode}".chomp
  end

  def aliquot_type
    f = facts.with_predicate('aliquotType').first
    f ? f.object : ""
  end

  def kind_of_plate?
    (asset_type=='Plate')||(asset_type=='TubeRack')
  end

  def kind_of_tube?
    (asset_type=='Tube')||(asset_type=='SampleTube')
  end

  def study_name
    if has_predicate?('study_name')
      return facts.with_predicate('study_name').first.object
    end
    return ''
  end

  def barcode_type
    btypes = facts.with_predicate('barcodeType')
    return 'ean13' if btypes.empty?
    btypes.first.object.downcase
  end

  def barcode_sequencescaped
    unless barcode.match(/^\d+$/)
      return barcode.match(/\d+/)[0] if barcode.match(/\d+/)
      return ""
    end
    ean13 = barcode.rjust(13, '0')
    ean13.slice!(0,3)
    ean13.slice!(ean13.length-3,3)
    ean13.to_i
  end

  def position_value
    val = facts.map(&:position).compact.first
    return "" if val.nil?
    "_#{(val.to_i+1).to_s}"
  end

  def purpose
    purposes_facts = facts.with_predicate('purpose')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end

  def aliquot
    purposes_facts = facts.with_predicate('aliquotType')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end

  def has_wells?
    (kind_of_plate? && (facts.with_predicate('contains').count > 0))
  end

  def contains_location?(location)
    facts.with_predicate('contains').any? do |f|
      f.object_asset.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def assets_at_location(location)
    facts.with_predicate('contains').map(&:object_asset).select do |a|
      a.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def remove_from_parent(parent)
    facts.with_predicate('parent').select{|f| f.object_asset==parent}.each(&:destroy)
    facts.with_predicate('location').each(&:destroy)
  end

  def is_sequencescape_plate?
    has_literal?('barcodeType', 'SequencescapePlate')
  end

end
