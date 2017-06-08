# frozen_string_literal: true
class BackgroundSteps::PurposeNameInference < Step
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('contains').select do |a|
      a.facts.with_predicate('contains').any? do |f|
        f.object_asset.has_predicate?('aliquotType')
      end
    end
  end

  def execute_actions
    update_attributes!(state: 'running',
                       step_type: StepType.find_or_create_by(name: 'PurposeNameInference'),
                       asset_group: AssetGroup.create!(assets: asset_group.assets))
    background_job(printer_config, user)
  end

  def purpose_for_aliquot(aliquot)
    return 'DNA Stock Plate' if aliquot == 'DNA'
    return 'RNA Stock Plate' if aliquot == 'RNA'
    'Stock Plate'
  end

  def purpose_for(asset)
    list = asset.facts.with_predicate('contains').map do |f|
      f.object_asset.facts.with_predicate('aliquotType').map(&:object)
    end.flatten.compact.uniq
    return '' if list.count > 1
    purpose_for_aliquot(list.first)
  end

  def background_job(_printer_config = nil, _user = nil)
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          add_facts(asset, [Fact.create(predicate: 'purpose', object: purpose_for(asset))])
        end
      end
    end
    update_attributes!(state: 'complete')
    asset_group.touch
  ensure
    update_attributes!(state: 'error') unless state == 'complete'
    asset_group.touch
  end

  handle_asynchronously :background_job
end
