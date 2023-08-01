require 'support_n3'

module ActivitiesHelper # rubocop:todo Style/Documentation
  def ontology_json
    return @ontology if @ontology

    ontology = File.new(Rails.root.to_s + '/app/assets/owls/root-ontology.ttl')
    @ontology = SupportN3.ontology_to_json(ontology).to_json.html_safe
  end

  def step_types_data_for_step_types(activity, step_types)
    step_types
      .select { |st| st.step_template.blank? }
      .map do |st|
        {
          createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(activity),
          stepType: st,
          name: st.name
        }
      end
  end

  def step_types_for_asset_groups_data(activity, asset_group)
    step_types = activity.step_types_for(asset_group.assets)
    {
      updateUrl: Rails.application.routes.url_helpers.activity_step_types_path(activity),
      stepTypesData: step_types_data_for_step_types(activity, step_types),
      stepTypesTemplatesData: step_type_templates_data_for_step_types(activity, step_types, asset_group)
    }
  end

  def step_types_control_data(activity)
    return {} if activity.running?

    activity
      .owned_asset_groups
      .reduce({}) do |memo, asset_group|
        data_for_step_types = step_types_for_asset_groups_data(activity, asset_group)
        memo[asset_group.id] = data_for_step_types
        memo
      end
  end

  def steps_data_for_steps(steps)
    steps.map do |step|
      username = (step && step.user) ? step.user.username : nil
      {
        stepUpdateUrl: Rails.application.routes.url_helpers.step_path(step),
        activity: step.activity,
        assetGroup: step.asset_group,
        step_type: step.step_type,
        operations: operations_data(step.operations),
        username: username
      }.merge(step.attributes)
    end
  end

  def steps_without_operations_data_for_steps(steps)
    steps.map do |step|
      { state: step.state, asset_group_id: step.asset_group.id, step_type_id: step.step_type.id, step_id: step.id }
    end
  end

  def operations_data(operations)
    operations
      .with_asset
      .includes(:object_asset, :asset)
      .map do |fact|
        fact.attributes.tap do |data|
          elem = fact.object_asset

          data['object_asset'] = {
            uuid: elem.uuid,
            barcode: elem.barcode,
            id: elem.id,
            info_line: elem.info_line
          } if elem

          data[:asset] = fact.asset.attributes
        end
      end
  end

  def facts_data(facts)
    facts.map do |fact|
      elem = fact.object_asset
      if elem
        { 'object_asset' => { uuid: elem.uuid, barcode: elem.barcode, id: elem.id, info_line: elem.info_line } }.merge(
          fact.attributes
        )
      else
        fact.attributes
      end
    end
  end

  def asset_data(asset)
    asset.facts.reload
    { barcode: asset.barcode, uuid: asset.uuid, facts: facts_data(asset.facts) }
  end

  def asset_group_data(activity, asset_group)
    {
      id: asset_group.id,
      activityId: asset_group.activity_owner.id,
      lastUpdate: asset_group.updated_at,
      updateUrl: Rails.application.routes.url_helpers.activity_asset_group_path(activity, asset_group),
      printUrl: Rails.application.routes.url_helpers.print_asset_group_path(asset_group),
      condition_group_name: asset_group.condition_group_name,
      name: asset_group.display_name,
      assets_running: activity.steps.running.joins(asset_group: :assets).map(&:assets).flatten.map(&:uuid).uniq,
      assets: asset_group.assets.map { |asset| asset_data(asset) }
    }
  end

  def asset_groups_data(activity)
    activity
      .owned_asset_groups
      .reduce({}) do |memo, asset_group|
        asset_group.assets.reload
        data_for_step_types = asset_group_data(activity, asset_group)
        memo[asset_group.id] = data_for_step_types
        memo
      end
  end

  def step_type_templates_data_for_step_types(activity, step_types, asset_group)
    step_types
      .select { |s| !s.step_template.blank? }
      .map do |st|
        {
          assetGroup: asset_group,
          createStepUrl: Rails.application.routes.url_helpers.activity_steps_path(activity),
          stepType: st,
          name: st.name,
          id: "step-type-id-#{rand(9999)}-#{st.id}"
        }
      end
  end

  def data_asset_display_for_asset_group(asset_group)
    asset_group.assets.each_with_object({}) { |asset, memo| memo[asset.uuid] = data_asset_display(asset.facts) }
  end

  def data_asset_display_for_activity(activity)
    activity
      .owned_asset_groups
      .reduce({}) { |memo, asset_group| memo.merge(data_asset_display_for_asset_group(asset_group)) }
  end

  def messages_for_activity(activity)
    activity
      .steps
      .failed
      .include_messages
      .flat_map(&:step_messages)
      .map { |m| { type: 'danger', msg: m.content.to_s.html_safe } }
  end
end
