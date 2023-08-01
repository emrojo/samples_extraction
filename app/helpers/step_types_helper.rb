module StepTypesHelper # rubocop:todo Style/Documentation
  def fact_css_classes
    {
      'addFacts' => 'glyphicon glyphicon-pencil',
      'removeFacts' => 'glyphicon glyphicon-erase',
      'createAsset' => 'glyphicon glyphicon-plus',
      'selectAsset' => 'glyphicon glyphicon-eye-open',
      'unselectAsset' => 'glyphicon glyphicon-eye-close',
      'checkFacts' => 'glyphicon glyphicon-search'
    }
  end

  def condition_groups_init_for_step_type(step_type)
    cgroups =
      step_type
        .condition_groups
        .reduce({}) do |memo, condition_group|
          name = condition_group.name || "a#{condition_group.id}"
          memo[name] = {
            cardinality: condition_group.cardinality,
            keepSelected: condition_group.keep_selected,
            facts:
              condition_group.conditions.map do |condition|
                {
                  cssClasses: fact_css_classes['checkFacts'],
                  name: name,
                  actionType: 'checkFacts',
                  predicate: condition.predicate,
                  object: condition.object
                }
              end
          }
          memo
        end
    agroups =
      step_type
        .actions
        .reduce(cgroups) do |memo, action|
          name = action.subject_condition_group.name || "a#{action.subject_condition_group.id}"
          memo[name] = {
            facts: [],
            cardinality: action.subject_condition_group.cardinality,
            keepSelected: action.subject_condition_group.keep_selected
          } unless memo[name]
          memo[name][:facts].push(
            {
              cssClasses: fact_css_classes[action.action_type],
              name: name,
              actionType: action.action_type,
              predicate: action.predicate,
              object: action.object
            }
          )
          memo
        end
    agroups.to_json
  end
end
