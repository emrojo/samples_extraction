module Assets::Export # rubocop:todo Style/Documentation
  class DuplicateLocations < StandardError
  end

  # NOTE: This is a little concerning, as it will only work for plates, and yet
  # pushTo is was also being set for wells (and tubeRacks, but that may be intentional)
  def update_sequencescape(user)
    FactChanges.new.tap do |updates|
      # remote (Sequencescape) updates
      instance = SequencescapeClient.version_1_find_by_uuid(uuid) || create_remote_plate

      create_or_update_remote_contained_assets(instance, user) unless attributes_to_send.empty?

      # local (Samples Extraction) updates
      old_barcode = barcode
      update(uuid: instance.uuid, barcode: code39_barcode(instance))

      update_wells(instance, updates)

      updates.add(self, 'beforeBarcode', old_barcode) if old_barcode
      updates.add_remote(self, 'purpose', purpose_name) if purpose_name
      updates.remove(facts.with_predicate('barcodeType'))
      updates.add(self, 'barcodeType', 'SequencescapePlate')

      mark_as_updated(updates)
      mark_to_print(updates) if old_barcode != barcode
    rescue SocketError
      updates.set_errors(['Sequencescape connection - Network connectivity issue'])
    rescue Errno::ECONNREFUSED => e
      updates.set_errors(['Sequencescape connection - The server is down.'])
    rescue Timeout::Error => e
      updates.set_errors(['Sequencescape connection - Timeout error occurred.'])
    rescue StandardError => e
      updates.set_errors(
        ['Sequencescape connection - There was an error while updating Sequencescape', e.message, e.backtrace.to_s]
      )
    end
  end

  def create_remote_plate
    SequencescapeClient.create_plate(purpose_name) if purpose_name
  end

  def create_or_update_remote_contained_assets(instance, user)
    # create the (remote) aliquots against the wells created above, or rearrange them (re-racking)
    SequencescapeClient.update_extraction_attributes(instance, attributes_to_send, user.username)
  end

  def mark_to_print(updates)
    updates.add(self, 'is', 'readyForPrint')
  end

  def code39_barcode(instance)
    instance.barcode.machine
  end

  def update_wells(remote_plate, _updates)
    remote_plate.wells.each do |remote_well|
      fact = fact_well_at(remote_well.location)
      if fact
        local_well = fact.object_asset
        if local_well && local_well.uuid != remote_well.uuid
          local_well.update(uuid: remote_well.uuid)
          fact.update(is_remote?: true)
        end
      end
    end
  end

  def fact_well_at(location)
    facts
      .with_predicate('contains')
      .detect do |f|
        if f.object_asset
          TokenUtil.unpad_location(f.object_asset.facts.with_predicate('location').first.object) ==
            TokenUtil.unpad_location(location)
        end
      end
  end

  def mark_as_updated(updates)
    updates.add(self, 'pushedTo', 'Sequencescape')
    facts
      .with_predicate('contains')
      .each do |f|
        updates.add(f.object_asset, 'pushedTo', 'Sequencescape') if f.object_asset.has_predicate?('sample_tube')
      end
  end

  def duplicate_locations_in_plate?
    locations =
      facts
        .with_predicate('contains')
        .map(&:object_asset)
        .map { |a| a.facts.with_predicate('location').map(&:object) }
        .flatten
        .compact
    (locations.uniq.length != locations.length)
  end

  def attributes_to_send
    raise DuplicateLocations if duplicate_locations_in_plate?

    facts.with_predicate('contains').map(&:object_asset).filter_map { |well| attributes_to_send_for_well(well) }
  end

  def has_sample?
    has_predicate_with_value?('supplier_sample_name') || has_relation_with_value?('sample_tube') ||
      has_predicate_with_value?('sample_uuid')
  end

  def attributes_to_send_for_well(well)
    # If it was already in SS, always export it
    if well.has_literal?('pushedTo', 'Sequencescape')
      return { uuid: well.uuid, location: TokenUtil.unpad_location(well.facts.with_predicate('location').first.object) }
    end

    # Do not export any well information unless it has a sample defined for it
    return nil unless well.has_sample?

    # extract the 'facts' that we want to send to Sequencescape for creation of wells
    well
      .facts
      .each_with_object({}) do |fact, memo|
        case fact.predicate
        when 'sample_tube'
          memo["#{fact.predicate}_uuid".to_sym] = fact.object_asset.uuid
        when 'location'
          memo[fact.predicate.to_sym] = TokenUtil.unpad_location(fact.object)
        when 'aliquotType', 'sanger_sample_id', 'sanger_sample_name', 'sample_uuid'
          memo[fact.predicate.to_sym] = TokenUtil.unquote(fact.object)
        end
      end
  end
end
