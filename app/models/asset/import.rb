# frozen_string_literal: true
module Asset::Import
  def step_for_import
    return @step_for_import if @step_for_import
    step_type = StepType.find_or_create_by(name: 'Import')
    @step_for_import = Step.new(step_type: step_type)
  end

  def annotate_container(asset, remote_asset)
    if remote_asset.try(:aliquots, nil)
      remote_asset.aliquots.each do |aliquot|
        step_for_import.add_facts(asset, Fact.create(predicate: 'sample_tube',
                                                     object_asset: asset))
        step_for_import.add_facts(asset, Fact.create(predicate: 'sanger_sample_id',
                                                     object: aliquot.sample.sanger.sample_id))
        step_for_import.add_facts(asset, Fact.create(predicate: 'sanger_sample_name',
                                                     object: aliquot.sample.sanger.name))
      end
    end
  end

  def sample_id_to_study_name(sample_id)
    sample_id.gsub(/\d*$/, '').delete('-')
  end

  def annotate_study_name_from_aliquots(asset, remote_asset)
    if remote_asset.try(:aliquots, nil)
      if remote_asset.aliquots.first.sample
        step_for_import.add_facts(asset, Fact.create(predicate: 'study_name',
                                                     object: sample_id_to_study_name(remote_asset.aliquots.first.sample.sanger.sample_id)))
      end
    end
  end

  def annotate_study_name(asset, remote_asset)
    if remote_asset.try(:wells, nil)
      remote_asset.wells.detect do |w|
        annotate_study_name_from_aliquots(asset, w)
      end
    else
      annotate_study_name_from_aliquots(asset, remote_asset)
    end
  end

  def annotate_wells(asset, remote_asset)
    if remote_asset.try(:wells, nil)
      remote_asset.wells.each do |well|
        local_well = Asset.create!(uuid: well.uuid)
        step_for_import.add_facts(asset, Fact.create(predicate: 'contains', object_asset: local_well))
        step_for_import.add_facts(local_well, Fact.create(predicate: 'a', object: 'Well'))
        step_for_import.add_facts(local_well, Fact.create(predicate: 'location', object: well.location))
        step_for_import.add_facts(local_well, Fact.create(predicate: 'parent', object_asset: asset))
        # local_well.add_facts(Fact.create(:predicate => 'aliquotType', :object => 'nap'))
        annotate_container(local_well, well)
      end
    end
  end

  def sequencescape_type_for_asset(remote_asset)
    remote_asset.class.to_s.gsub(/Sequencescape::/, '')
  end

  def keep_sync_with_sequencescape?(remote_asset)
    class_name = sequencescape_type_for_asset(remote_asset)
    (class_name != 'SampleTube')
  end

  def build_asset_from_remote_asset(barcode, remote_asset)
    ActiveRecord::Base.transaction do |_t|
      asset = Asset.create(barcode: barcode, uuid: remote_asset.uuid)
      class_name = sequencescape_type_for_asset(remote_asset)
      step_for_import.add_facts(asset, Fact.create(predicate: 'a', object: class_name))

      if keep_sync_with_sequencescape?(remote_asset)
        step_for_import.add_facts(asset, Fact.create(predicate: 'pushTo', object: 'Sequencescape'))
        if remote_asset.try(:plate_purpose, nil)
          step_for_import.add_facts(asset, Fact.create(predicate: 'purpose',
                                                       object: remote_asset.plate_purpose.name))
        end
      end
      step_for_import.add_facts(asset, Fact.create(predicate: 'is', object: 'NotStarted'))

      annotate_container(asset, remote_asset)
      annotate_wells(asset, remote_asset)
      annotate_study_name(asset, remote_asset)
      asset
    end
  end

  def find_or_import_asset_with_barcode(barcode)
    unless barcode =~ /^\d+$/
      barcode = Barcode.calculate_barcode(barcode[0, 2], barcode[2, barcode.length - 3].to_i).to_s
    end

    asset = Asset.find_by_barcode(barcode)
    asset = Asset.find_by_uuid(barcode) unless asset
    unless asset
      if Barcode.is_creatable_barcode?(barcode)
        asset = Asset.create!(barcode: barcode)
        step_for_import.add_facts(asset, Fact.create!(predicate: 'a', object: 'Tube'))
        step_for_import.add_facts(asset, Fact.create!(predicate: 'barcodeType', object: 'Code2D'))
        step_for_import.add_facts(asset, Fact.create!(predicate: 'is', object: 'Empty'))
      end
    end
    unless asset
      remote_asset = SequencescapeClient.get_remote_asset(barcode)
      if remote_asset
        asset = build_asset_from_remote_asset(barcode, remote_asset)
        raise 'Asset not found' if asset.nil?
      end
      asset.update_compatible_activity_type
    end
    asset
  end
end
