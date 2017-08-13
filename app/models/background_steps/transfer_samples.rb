class BackgroundSteps::TransferSamples < Step
  include PlateTransfer
  def assets_compatible_with_step_type
    (asset_group.assets.with_predicate('transferredFrom').count > 0) ||
      (asset_group.assets.with_predicate('transfer').count > 0)
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'TransferSamples'),
      :asset_group => asset_group
    })
    background_job
  end

  def each_asset_and_modified_asset(&block)
    asset_group.assets.with_predicate('transfer').each do |asset|
      asset.facts.with_predicate('transfer').each do |fact|
        modified_asset = fact.object_asset
        yield(asset, modified_asset) if asset && modified_asset
      end
    end
    asset_group.assets.with_predicate('transferredFrom').each do |modified_asset|
      modified_asset.facts.with_predicate('transferredFrom').each do |fact|
        asset = fact.object_asset
        yield(asset, modified_asset) if asset && modified_asset
      end
    end    
  end

  def background_job
    return unless assets_compatible_with_step_type

    ActiveRecord::Base.transaction do
      each_asset_and_modified_asset do |asset, modified_asset|
        added_facts = []
        added_facts.push([Fact.new(:predicate => 'is', :object => 'Used')])
        if (asset.has_predicate?('sample_tube'))
          added_facts.push([Fact.new(:predicate => 'sample_tube', 
            :object_asset => asset.facts.with_predicate('sample_tube').first.object_asset)])
        end
        if (asset.has_predicate?('study_name'))
          added_facts.push([Fact.new(:predicate => 'study_name', 
            :object => asset.facts.with_predicate('study_name').first.object)])
        end        
        added_facts.push(asset.facts.with_predicate('sanger_sample_id').map do |aliquot_fact|
          [
            Fact.new(:predicate => 'sanger_sample_id', :object => aliquot_fact.object),
            Fact.new(:predicate => 'sample_id', :object => aliquot_fact.object)
          ]
        end.flatten)
        unless modified_asset.has_predicate?('aliquotType')
          added_facts.concat(asset.facts.with_predicate('aliquotType').map do |aliquot_fact|
            [
              Fact.new(:predicate => 'aliquotType', :object => aliquot_fact.object)
            ]
          end.flatten)
        end
        added_facts.push(Fact.new(:predicate => 'transferredFrom', :object_asset => asset))
        added_facts = added_facts.flatten
        add_facts(modified_asset, added_facts)

        transfer(asset, modified_asset)
      end
      asset_group.touch
      update_attributes!(:state => 'complete')
    end
  ensure
    update_attributes!(:state => 'error') unless state == 'complete'
    asset_group.touch    
  end

  handle_asynchronously :background_job

end