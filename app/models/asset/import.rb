module Asset::Import

  UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  class RefreshSourceNotFoundAnymore < StandardError ; end

  module InstanceMethods

    def json_for_remote(remote_asset)
      distinct = remote_asset.attribute_groups.to_json

      # It would be useful to have a hashcode in the sequencescape client api to know
      # if this message is different from a previous one without needing to traverse
      # all the object finding the change
      # Having a :to_json method that returns a json would be pretty sensible too

      # FOR A PLATE
      if remote_asset.respond_to?(:wells) && remote_asset.wells
        # wells.to_a because wells relation does not act as an array
        listw = remote_asset.wells.to_a
        if listw
          # aliquots.to_a, same reason
          listal = listw.compact.map(&:aliquots).map(&:to_a)
          if listal
            listsa = listal.flatten.compact.map{|al| al.sample }
            if listsa
              distinct+=listsa.compact.map(&:updated_at).uniq.to_s
            end
          end
        end
      end

      # FOR A TUBE
      if remote_asset.respond_to?(:aliquots) && remote_asset.aliquots
        # aliquots.to_a, same reason
        listal = remote_asset.aliquots.to_a
        if listal
          listsa = listal.flatten.compact.map{|al| al.sample }
          if listsa
            distinct+=listsa.compact.map(&:updated_at).uniq.to_s
          end
        end
      end

      distinct
    end

    def update_digest_with_remote(remote_asset)
      update_attributes(remote_digest: Digest::MD5::hexdigest(json_for_remote(remote_asset)))
    end    

    def changed_remote?(remote_asset)
      Digest::MD5::hexdigest(json_for_remote(remote_asset)) != remote_digest
    end

    def assets_to_refresh
      # We need to destroy also the remote facts of the contained wells on refresh
      [self, facts.with_predicate('contains').map(&:object_asset).select do |asset|
        asset.facts.from_remote_asset.count > 0
      end].flatten
    end

    def get_import_step
      @import_step
    end    

    def _process_refresh(remote_asset)
      ActiveRecord::Base.transaction do 
        asset_group = AssetGroup.new
        @import_step.update_attributes(asset_group: asset_group)

        asset_group.update_attributes(assets: assets_to_refresh)

        # Removes previous state
        assets_to_refresh.each do |asset|
          list_facts = asset.facts.from_remote_asset
          asset.remove_operations(list_facts, @import_step)
          list_facts.each(&:destroy)
        end

        # Loads new state
        self.class.update_asset_from_remote_asset(self, remote_asset)

        @import_step.update_attributes(state: 'complete')
        asset_group.touch
      end
    ensure
      @import_step.update_attributes(state: 'error') unless @import_step.state == 'complete'
      @import_step.asset_group.touch if @import_step.asset_group
    end

    def is_refreshing_right_now?
      Step.running_with_asset(self).count > 0
    end

    def type_of_asset_for_sequencescape
      if ((facts.with_predicate('a').first) && (facts.with_predicate('a').first.object.include?("Tube")))
        :tube
      else
        :plate
      end
    end

    def refresh
      if is_remote_asset?
        remote_asset = SequencescapeClient::find_by_uuid(uuid, type = type_of_asset_for_sequencescape)
        raise RefreshSourceNotFoundAnymore unless remote_asset
        if changed_remote?(remote_asset)
          unless is_refreshing_right_now?
            @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
            _process_refresh(remote_asset)
          end
        end
      end
      self
    end

    def refresh!
      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Refresh!!'), state: 'running')      
      remote_asset = SequencescapeClient::find_by_uuid(uuid, type = type_of_asset_for_sequencescape)
      raise RefreshSourceNotFoundAnymore unless remote_asset
      _process_refresh(remote_asset)
      self      
    end

    def is_remote_asset?
      facts.from_remote_asset.count > 0
    end

    def update_facts_from_remote(list, step=nil)
      step = step || @import_step
      list = [list].flatten
      added = list.map do |f| 
        f.assign_attributes(:is_remote? => true) 
        f
      end
      facts << added
      add_operations([added].flatten, step)
    end

  end

  module ClassMethods

    def import(barcode)
      asset = nil

      @import_step = Step.create(step_type: StepType.find_or_create_by(name: 'Import'), state: 'running')      
      remote_asset = SequencescapeClient::get_remote_asset(barcode)
      if remote_asset
        asset = Asset.create(barcode: barcode, uuid: remote_asset.uuid)
        asset.update_facts_from_remote(Fact.new(:predicate => 'a', :object => sequencescape_type_for_asset(remote_asset)))
        asset.facts << Fact.new(predicate: 'remoteAsset', object: remote_asset.uuid, is_remote?: true)
        asset.save
        asset.refresh
        asset.update_compatible_activity_type
      end
      asset
    end    

    def create_local_asset(barcode)
      asset=nil
      ActiveRecord::Base.transaction do
        asset = Asset.create!(:barcode => barcode)
        asset.update_facts_from_remote([
          Fact.new(:predicate => 'a', :object => 'Tube', is_remote?: true), 
          Fact.new(:predicate => 'barcodeType', :object => 'Code2D', is_remote?: true),
          Fact.new(:predicate => 'is', :object => 'Empty', is_remote?: true)
          ])
      end
      asset   
    end

    def is_local_asset?(barcode)
      Barcode.is_creatable_barcode?(barcode.to_s)      
    end

    def is_digit_barcode?(barcode)
      barcode.to_s.match(/^\d+$/)
    end

    def is_uuid?(str)
      UUID_REGEXP.match(str)
    end

    def find_asset_with_barcode(barcode)
      barcode = barcode.to_s
      unless is_digit_barcode?(barcode) || is_uuid?(barcode)
        barcode = Barcode.calculate_barcode(barcode[0,2], barcode[2, barcode.length-3].to_i).to_s
      end
      
      asset = Asset.find_by_barcode(barcode)
      asset = Asset.find_by_uuid(barcode) unless asset
      asset = Asset.create_local_asset if asset.nil? && is_local_asset?(barcode)      
      if asset
        asset.refresh
      end
      asset
    end

    def find_or_import_asset_with_barcode(barcode)
      find_asset_with_barcode(barcode) || import(barcode)
    end

    def update_asset_from_remote_asset(asset, remote_asset)
      class_name = sequencescape_type_for_asset(remote_asset)
      asset.update_facts_from_remote(Fact.new(:predicate => 'a', :object => class_name))

      if keep_sync_with_sequencescape?(remote_asset)
        asset.update_facts_from_remote(Fact.new(predicate: 'pushTo', object: 'Sequencescape'))
        if remote_asset.try(:plate_purpose, nil)
          asset.update_facts_from_remote(Fact.new(:predicate => 'purpose',
          :object => remote_asset.plate_purpose.name))
        end
      end
      asset.update_facts_from_remote(Fact.new(:predicate => 'is', :object => 'NotStarted'))

      annotate_container(asset, remote_asset)
      annotate_wells(asset, remote_asset)
      annotate_study_name(asset, remote_asset)

      asset.update_digest_with_remote(remote_asset)
    end

    def annotate_container(asset, remote_asset, step=nil)
      step = step || asset.get_import_step
      if remote_asset.try(:aliquots, nil)
        remote_asset.aliquots.each do |aliquot|
          asset.update_facts_from_remote(Fact.new(:predicate => 'sample_tube',
            :object_asset => asset), step)
          asset.update_facts_from_remote(Fact.new(:predicate => 'sanger_sample_id',
            :object => aliquot.sample.sanger.sample_id), step)
          asset.update_facts_from_remote(Fact.new(:predicate => 'sanger_sample_name',
            :object => aliquot.sample.sanger.name), step)
          asset.update_facts_from_remote(Fact.new(predicate: 'supplier_sample_name', 
            object: aliquot.sample.supplier.sample_name), step)        
        end
      end
    end

    def sample_id_to_study_name(sample_id)
      sample_id.gsub(/\d*$/,'').gsub('-', '')
    end

    def annotate_study_name_from_aliquots(asset, remote_asset)
      if remote_asset.try(:aliquots, nil)
        if ((remote_asset.aliquots.count == 1) && (remote_asset.aliquots.first.sample))
          asset.update_facts_from_remote(Fact.new(predicate: 'study_name', 
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
          local_well = Asset.find_or_create_by(:uuid => well.uuid)
          # Updated wells will also mean that the plate is out of date, so we'll set it in the asset
          local_well.update_facts_from_remote(Fact.new(:predicate => 'a', :object => 'Well'), asset.get_import_step)
          local_well.update_facts_from_remote(Fact.new(:predicate => 'location', :object => well.location), asset.get_import_step)
          local_well.update_facts_from_remote(Fact.new(:predicate => 'parent', :object_asset => asset), asset.get_import_step)
          asset.update_facts_from_remote(Fact.new(:predicate => 'contains', :object_asset => local_well))

          if (well.try(:aliquots, nil)&.first&.sample&.supplier&.sample_name)
            annotate_container(local_well, well, asset.get_import_step)
          end
        end
      end
    end

    def sequencescape_type_for_asset(remote_asset)
      type = remote_asset.class.to_s.gsub(/Sequencescape::/,'')
      return 'SampleTube' if type == 'Tube'
      return type
    end

    def keep_sync_with_sequencescape?(remote_asset)
      class_name = sequencescape_type_for_asset(remote_asset)
      (class_name != 'SampleTube')
    end

  end
end
