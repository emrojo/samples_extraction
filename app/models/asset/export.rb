# frozen_string_literal: true
module Asset::Export
  def step_for_export
    step_type = StepType.find_or_create_by(name: 'Export')
    step = Step.new(step_type: step_type)
  end

  def update_sequencescape(print_config, user)
    instance = SequencescapeClient.find_by_uuid(uuid)
    unless instance
      instance = SequencescapeClient.create_plate(class_name, {}) if class_name
    end
    unless attributes_to_update.empty?
      SequencescapeClient.update_extraction_attributes(instance, attributes_to_update, user.username)
    end

    # We update current plate with the uuids from the server
    instance = SequencescapeClient.find_by_uuid(uuid)

    facts.each { |f| f.update_attributes!(up_to_date: true) }
    old_barcode = barcode
    update_attributes(uuid: instance.uuid, barcode: instance.barcode.ean13)
    step_for_export.add_facts(self, Fact.create(predicate: 'beforeBarcode', object: old_barcode))
    step_for_export.add_facts(self, Fact.create(predicate: 'purpose', object: class_name))
    step_for_export.remove_facts(self, facts.with_predicate('barcodeType'))
    step_for_export.add_facts(self, Fact.create(predicate: 'barcodeType', object: 'SequencescapePlate'))
    mark_as_updated
    print(print_config, user.username) if old_barcode != barcode
  end

  def update_plate(instance)
    instance.wells.each do |well|
      w = well_at(well.location)
      w.update_attributes(uuid: well.uuid) if w && w.uuid != well.uuid
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
    step_for_export.add_facts(self, Fact.create(predicate: 'pushedTo', object: 'Sequencescape'))
    facts.with_predicate('contains').each do |f|
      if f.object_asset.has_predicate?('sample_tube')
        step_for_export.add_facts(f.object_asset, Fact.create(predicate: 'pushedTo', object: 'Sequencescape'))
      end
    end
  end

  def validate_racking_info?(data)
    unless data.first[:location].nil?
      # Disallows duplicated locations
      return (data.map { |n| n[:location] }.compact.uniq.count == data.count)
    end
    true
  end

  def attributes_to_update
    data = facts.with_predicate('contains').map(&:object_asset).uniq.map do |well|
      racking_info(well)
    end

    return data if validate_racking_info?(data)
    raise 'Invalid racking info provided'
  end

  def racking_info(well)
    if well.has_literal?('pushedTo', 'Sequencescape')
      return {
        uuid: well.uuid,
        location: well.facts.with_predicate('location').first.object
      }
    end
    data = {}
    # unless well.has_predicate?('sample_tube')
    #  data[:uuid] = well.uuid
    # end
    well.facts.each_with_object({}) do |fact, memo|
      if ['sample_tube'].include?(fact.predicate)
        memo["#{fact.predicate}_uuid".to_sym] = fact.object_asset.uuid
      end

      if %w(location aliquotType sanger_sample_id
            sanger_sample_name sample_uuid).include?(fact.predicate)
        memo[fact.predicate.to_sym] = fact.object
      end
    end
  end
end
