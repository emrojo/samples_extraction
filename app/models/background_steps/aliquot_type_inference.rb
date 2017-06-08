# frozen_string_literal: true
class BackgroundSteps::AliquotTypeInference < Step
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('aliquotType').select { |a| a.has_predicate?('contains') }
  end

  def execute_actions
    update_attributes!(state: 'running',
                       step_type: StepType.find_or_create_by(name: 'AliquotTypeInference'),
                       asset_group: AssetGroup.create!(assets: asset_group.assets))
    background_job(printer_config, user)
  end

  def aliquot_type_fact(asset)
    asset.facts.with_predicate('aliquotType').first
  end

  def background_job(_printer_config = nil, _user = nil)
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          unless asset.facts.with_predicate('contains').map(&:object_asset).any? do |o|
                   o.has_predicate?('aliquotType')
                 end
            asset.facts.with_predicate('contains').map(&:object_asset).each do |o|
              add_facts(o, [Fact.create(predicate: 'aliquotType', object: aliquot_type_fact(asset).object)])
            end
          end
          remove_facts(asset, [aliquot_type_fact(asset)])
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
