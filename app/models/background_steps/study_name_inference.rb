# frozen_string_literal: true
class BackgroundSteps::StudyNameInference < Step
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('contains').select do |a|
      a.facts.with_predicate('contains').any? do |f|
        f.object_asset.has_predicate?('study_name')
      end
    end
  end

  def execute_actions
    update_attributes!(state: 'running',
                       step_type: StepType.find_or_create_by(name: 'StudyNameInference'),
                       asset_group: AssetGroup.create!(assets: asset_group.assets))
    background_job(printer_config, user)
  end

  def study_name_for(asset)
    list = asset.facts.with_predicate('contains').map do |f|
      f.object_asset.facts.with_predicate('study_name').map(&:object)
    end.flatten.compact.uniq
    return '' if list.count > 1
    list.first
  end

  def background_job(_printer_config = nil, _user = nil)
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          add_facts(asset, [Fact.create(predicate: 'study_name', object: study_name_for(asset))])
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
