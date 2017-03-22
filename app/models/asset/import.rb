module Asset::Import

  def annotate_container(asset, remote_asset)
    if remote_asset.try(:aliquots, nil)
      remote_asset.aliquots.each do |aliquot|
        asset.add_facts(Fact.create(:predicate => 'sample_tube',
          :object_asset => asset))
        asset.add_facts(Fact.create(:predicate => 'sanger_sample_id',
          :object => aliquot.sample.sanger.sample_id))
        asset.add_facts(Fact.create(:predicate => 'sanger_sample_name',
          :object => aliquot.sample.sanger.name))
      end
    end
  end

  def annotate_wells(asset, remote_asset)
    if remote_asset.try(:wells, nil)
      remote_asset.wells.each do |well|
        local_well = Asset.create!
        asset.add_facts(Fact.create(:predicate => 'contains', :object_asset => local_well))
        local_well.add_facts(Fact.create(:predicate => 'a', :object => 'Well'))
        local_well.add_facts(Fact.create(:predicate => 'location', :object => well.location))
        local_well.add_facts(Fact.create(:predicate => 'parent', :object_asset => asset))
        #local_well.add_facts(Fact.create(:predicate => 'aliquotType', :object => 'nap'))
        annotate_container(local_well, well)
      end
    end
  end

  def build_asset_from_remote_asset(barcode, remote_asset)
    ActiveRecord::Base.transaction do |t|
      asset = Asset.create(:barcode => barcode, :uuid => remote_asset.uuid)
      class_name = remote_asset.class.to_s.gsub(/Sequencescape::/,'')
      asset.add_facts(Fact.create(:predicate => 'a', :object => class_name))

      #if class_name == 'SampleTube'
      #  asset.add_facts(Fact.create(:predicate => 'aliquotType', :object => 'nap'))
      #end

      if remote_asset.try(:purpose, nil) && (class_name != 'SampleTube')
        asset.add_facts(Fact.create(:predicate => 'purpose',
        :object => remote_asset.purpose.name))
      end
      asset.add_facts(Fact.create(:predicate => 'is', :object => 'NotStarted'))

      annotate_container(asset, remote_asset)
      annotate_wells(asset, remote_asset)
      asset
    end
  end

  def find_or_import_asset_with_barcode(barcode)
    asset = Asset.find_by_barcode(barcode)
    asset = Asset.find_by_uuid(barcode) unless asset
    unless asset
      if Barcode.is_creatable_barcode?(barcode)
        asset = Asset.create!(:barcode => barcode)
        asset.facts << Fact.create!(:predicate => 'a', :object => 'Tube')
        asset.facts << Fact.create!(:predicate => 'barcodeType', :object => 'Code2D')
        asset.facts << Fact.create!(:predicate => 'is', :object => 'Empty')
      end
    end
    unless asset
      remote_asset = SequencescapeClient::get_remote_asset(barcode)
      if remote_asset
        asset = build_asset_from_remote_asset(barcode, remote_asset)
        raise 'Asset not found' if asset.nil?
      end
      asset.update_compatible_activity_type
    end
    asset
  end

end
