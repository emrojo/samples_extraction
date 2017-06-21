# frozen_string_literal: true
module InferenceEngines
  module Default
    module Actions
      module FactActions
        def add_facts
          msg = 'You cannot add facts to an asset not present in the conditions'
          raise Step::UnknownConditionGroup, msg if changed_assets.compact.empty?
          @changed_facts = generate_facts
          changed_assets.each do |asset|
            asset.add_facts(changed_facts.map(&:dup), position) do |fact|
              create_operation(asset, fact)
            end
          end
        end

        def remove_facts
          changed_assets.each_with_index do |asset, _idx|
            @changed_facts = asset.facts.select do |f|
              ((f.predicate == action.predicate) &&
              (((action.object.nil? || (f.object == action.object))) ||
                (f.object_asset && action.object_condition_group.compatible_with?(f.object_asset))))
            end.select do |f|
              position.nil? || f.object_asset.nil? ? true : (position_for_asset(f.object_asset, action.object_condition_group) == position)
            end.each do |fact|
              create_operation(asset, fact)
            end
            if facts_to_destroy.nil?
              @changed_facts.each do |fact|
                fact.update_attributes(to_remove_by: step.id)
              end
            else
              facts_to_destroy.push(@changed_facts)
            end
          end
        end

        def wildcard_facts
          if action.object_condition_group.is_wildcard?
            values = []
            if action && action.object_condition_group && asset
              values = step.wildcard_values[action.object_condition_group.id].values.reduce([]) do |memo, values|
                my_value = step.wildcard_values[action.object_condition_group.id][asset.id] || []
                result = my_value.empty? ? values : (values.to_set & my_value.to_set).to_a
                memo.push(result).flatten.uniq
              end
              # values = step.wildcard_values[action.object_condition_group.id][asset.id] || []
            end
            values.map do |value|
              if action.subject_condition_group.runtime_conditions_compatible_with?(asset, value)
                if value.is_a? Asset
                  {
                    predicate: action.predicate,
                    object: value.name,
                    object_asset: value,
                    literal: false
                  }
                else
                  {
                    predicate: action.predicate,
                    object: value,
                    object_asset_id: nil,
                    literal: true
                  }
                end
              end
            end
          end
        end

        def position_for_asset(asset, condition_group)
          positions_for_asset[asset] = {} unless positions_for_asset[asset]
          unless positions_for_asset[asset][condition_group]
            positions_for_asset[asset][condition_group] = step.step_type.position_for_assets_by_condition_group([asset])
          end
          positions_for_asset[asset][condition_group]
        end

        def generate_facts
          data = {}
          # debugger if action.predicate == 'aliquotType'
          # debugger if action.predicate == 'relation_r'

          if action.object_condition_group.nil?
            data = [{ predicate: action.predicate, object: action.object }]
          else
            if created_assets[action.object_condition_group.id].nil?
              if action.object_condition_group.is_wildcard?
                # A wildcard value might be an asset as well, not just values
                # we need to add support to them
                data = wildcard_facts
              else
                data = asset_group.assets.each_with_index.map.select do |related_asset, _idx|
                  # They are compatible if the object condition group is
                  # compatible and if they share a common range of values of
                  # values for any of the wildcard values defined
                  checked_wildcards = true
                  if step.wildcard_values && !step.wildcard_values.empty? && asset
                    checked_wildcards = step.wildcard_values.all? do |_cg_id, data|
                      if asset && related_asset && (data[asset.id] && data[related_asset.id])
                        !(data[asset.id] & data[related_asset.id]).empty?
                      else
                        true
                      end
                    end
                  end
                  runtime_conditions = true
                  if asset
                    runtime_conditions = action.subject_condition_group.runtime_conditions_compatible_with?(asset, related_asset)
                  end

                  result = action.object_condition_group.compatible_with?(related_asset) && checked_wildcards &&
                           runtime_conditions

                  dependency_compatibility = true
                  if asset && result
                    dependency_compatibility = step.step_type.check_dependency_compatibility_for(asset, action.subject_condition_group, asset_group.assets)
                  end

                  result && dependency_compatibility
                end.map do |related_asset, _idx|
                  {
                    position: position_for_asset(related_asset, action.object_condition_group),
                    predicate: action.predicate,
                    object: related_asset.relation_id,
                    object_asset_id: related_asset.id,
                    literal: false

                  }
                end
              end
            else
              data = created_assets[action.object_condition_group.id].each_with_index.map do |related_asset, idx|
                {
                  position: idx, # position_for_asset(related_asset, action.object_condition_group),
                  predicate: action.predicate,
                  object: related_asset.relation_id,
                  object_asset_id: related_asset.id,
                  literal: false
                }
              end
            end
          end
          in_progress = step.in_progress? ? { to_add_by: step.id } : {}
          data.compact.map do |obj|
            created_fact_obj = obj.merge(in_progress)
            created_fact_obj = created_fact_obj.delete_if { |k, _v| (k == :position) && (step.step_type.connect_by != 'position') }
            Fact.new(created_fact_obj)
          end
        end
      end
    end
  end
end
