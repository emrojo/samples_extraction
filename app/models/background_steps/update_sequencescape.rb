class BackgroundSteps::UpdateSequencescape < Step
  attr_accessor :printer_config

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('pushTo', 'Sequencescape').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'UpdateSequencescape'),
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_fact('pushTo', 'Sequencescape'))
    })
    background_job
  end


  def background_job
    return unless assets_compatible_with_step_type
    asset_group.assets.each do |asset|
      asset.update_sequencescape(printer_config)
      removed_facts = asset.facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}
      asset.remove_operations(removed_facts, self)
      removed_facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}.each do |f|
        f.destroy
      end
    end
    asset_group.touch
    update_attributes!(:state => 'complete')
  end

  handle_asynchronously :background_job

end