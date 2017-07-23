module Asset::Export

  def update_sequencescape(print_config, user)
    instance = SequencescapeClient.find_by_uuid(uuid)
    unless instance
      instance = SequencescapeClient.create_plate(class_name, {}) if class_name
    end
    unless attributes_to_update.empty?
      SequencescapeClient.update_extraction_attributes(instance, attributes_to_update, user.username)
    end

    update_plate(instance)

    facts.each {|f| f.update_attributes!(:up_to_date => true)}
    old_barcode = barcode
    update_attributes(:uuid => instance.uuid, :barcode => instance.barcode.ean13)
    add_facts(Fact.create(:predicate => 'beforeBarcode', :object => old_barcode))
    add_facts(Fact.create(predicate: 'purpose', object: class_name))
    facts.with_predicate('barcodeType').each(&:destroy)
    add_facts(Fact.create(:predicate => 'barcodeType', :object => 'SequencescapePlate'))
    mark_as_updated
    print(print_config, user.username) if old_barcode != barcode
  end

  def update_plate(instance)
    instance.wells.each do |well|
      w = well_at(well.location)
      if w && w.uuid != well.uuid
        w.update_attributes(uuid: well.uuid)
      end
    end
  end

  def well_at(location)
    f = facts.with_predicate('contains').select do |f| 
      f.object_asset.facts.with_predicate('location').first.object == location
    end.first
    return f.object_asset if f
    nil
  end

  def mark_as_updated
    add_facts(Fact.create(predicate: 'pushedTo', object: 'Sequencescape'))
    facts.with_predicate('contains').each do |f|
      if f.object_asset.has_predicate?('sample_tube')
        f.object_asset.add_facts(Fact.create(predicate: 'pushedTo', object: 'Sequencescape'))
      end
    end
  end


  def duplicate_locations_in_plate?
    locations = facts.with_predicate('contains').map(&:object_asset).map do |a| 
      a.facts.with_predicate('location').map(&:object)
    end.flatten.compact
    (locations.uniq.length != locations.length)
  end

  def attributes_to_update
    raise 'Duplicate locations in plate' if duplicate_locations_in_plate?
    facts.with_predicate('contains').map(&:object_asset).map do |well|
      racking_info(well)
    end
  end

  def racking_info(well)
    if well.has_literal?('pushedTo', 'Sequencescape')
      return { 
        uuid: well.uuid, 
        location: well.facts.with_predicate('location').first.object
      }
    end
    data = {}
    #unless well.has_predicate?('sample_tube')
    #  data[:uuid] = well.uuid
    #end
    well.facts.reduce({}) do |memo, fact|
      if (['sample_tube'].include?(fact.predicate))
        memo["#{fact.predicate}_uuid".to_sym] = fact.object_asset.uuid
      end

      if (['location', 'aliquotType', 'sanger_sample_id',
        'sanger_sample_name', 'sample_uuid'].include?(fact.predicate))
        memo[fact.predicate.to_sym] = fact.object
      end
      memo
    end    
  end

end
