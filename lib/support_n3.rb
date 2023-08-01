module SupportN3 # rubocop:todo Style/Documentation
  def self.ontology_to_json(ontology_file)
    reading_instance = nil
    data = {}
    definitions = {}
    inheritance = {}
    ontology =
      RDF::N3::Reader
        .new(ontology_file, { validate: false, canonicalize: false })
        .quads
        .reduce({}) do |memo, quad|
          subject = quad[0].pname
          predicate = quad[1].pname
          object = quad[2].to_s

          if reading_instance != subject
            if data['rdfs:label']
              memo[data['rdfs:label']] = data
              definitions[reading_instance] = data['rdfs:label']
            end
            data = { uri: subject }
            reading_instance = subject
          end

          if predicate == 'rdfs:subClassOf'
            inheritance[subject] = [subject] unless inheritance[subject]
            inheritance[subject].push(object)
          end

          predicate = 'description' if predicate == 'http://purl.org/dc/elements/1.1/description'
          data[predicate] = object
          memo
        end

    ontology.keys.each do |key|
      if ontology[key]['rdfs:domain']
        if inheritance[ontology[key]['rdfs:domain']]
          ontology[key]['rdfs:domain'] =
            inheritance[ontology[key]['rdfs:domain']].reduce([]) do |memo, uri|
              memo.push(definitions[uri])
              memo
            end
        else
          definitions[ontology[key]['rdfs:domain']]
        end
      end
      if ontology[key]['rdfs:range']
        if inheritance[ontology[key]['rdfs:range']]
          ontology[key]['rdfs:range'] =
            inheritance[ontology[key]['rdfs:range']].reduce([]) do |memo, uri|
              memo.push(definitions[uri])
              memo
            end
        else
          definitions[ontology[key]['rdfs:range']]
        end
      end
    end
    ontology
  end

  def self.parse_string(input, options = {}, step_type = nil)
    options = { validate: false, canonicalize: false }.merge(options)

    RuleGraphAccessor.parse_rules(RDF::N3::Reader.new(input, options).quads, step_type)
  end

  def self.parse_file(file_path)
    RDF::N3::Reader.open(file_path) { |reader| RuleGraphAccessor.parse_rules(reader.quads) }
  end

  def self.fragment(k)
    k.try(:fragment) || (k.try(:name) || k).to_s.gsub(/.*#/, '')
  end

  def self.build_asset(name, create_assets = true, created_assets = [])
    if create_assets
      asset = Asset.find_or_create_by(name: name)
    else
      asset = created_assets.find { |a| a.name == name }
      unless asset
        asset = Asset.create(name: name)
        created_assets.push(asset)
      end
    end
    asset
  end

  def self.is_literal?(element, quads)
    element.literal? || quads.none? { |q| q[0] == element }
  end

  def self.load_step_actions(content, options = {})
    options = { validate: false, canonicalize: false }.merge(options)

    # puts content
    open_resource = RDF::N3::Reader.new(content, options)
    quads = open_resource.quads
    quads.reduce({}) do |memo, quad|
      # If it is a step added to the root graph of the document
      if (fragment(quad[0]) == 'step') && (quad[3].nil?)
        memo[fragment(quad[1]).to_sym] = [] unless memo[fragment(quad[1]).to_sym]
        memo[fragment(quad[1]).to_sym].push(subgraph(quad[2], quads))
      end
      memo
    end
  end

  def self.subgraph(node, quads)
    quads.select { |q| q[3] == node }
  end

  def self.create_fact(quad, quads, create_assets = true, created_assets = [])
    asset = build_asset(SupportN3.fragment(quad[0]), create_assets, created_assets)
    if is_literal?(quad[2], quads)
      asset.facts << Fact.create(predicate: SupportN3.fragment(quad[1]), object: SupportN3.fragment(quad[2]))
    else
      related_asset = build_asset(SupportN3.fragment(quad[2]), create_assets, created_assets)
      asset.facts << Fact.create(predicate: SupportN3.fragment(quad[1]), object_asset: related_asset, literal: false)
    end
    asset
  end

  def self.parse_facts(input, options = {}, create_assets = true)
    options = { validate: false, canonicalize: false }.merge(options)

    created_assets = [] unless create_assets

    quads = RDF::N3::Reader.new(input, options).quads.clone
    quads.map { |quad| create_fact(quad, quads, create_assets, created_assets) }.sort_by { |a| a.name }.uniq
  end

  class RuleGraphAccessor # rubocop:todo Style/Documentation
    attr_reader :quads,
                :graph_conditions,
                :graph_consequences,
                :c_groups,
                :c_groups_cardinalities,
                :conditions,
                :actions,
                :step_type

    def self.rules(quads)
      quads.select { |quad| fragment(quad[1]) == 'implies' }
    end

    def self.parse_rules(quads, enforce_step_type = nil)
      self.activity_type = nil
      deprecate_class_by_name(ActivityType, activity_type_name(quads), activity_type(quads)) do |_old_instances|
        RuleGraphAccessor
          .rules(quads)
          .each do |k, _p, v, _g|
            accessor = RuleGraphAccessor.new(enforce_step_type, quads, k, v)
            accessor.execute
          end
      end
    end

    def self.deprecate_class_by_name(class_type, name, new_instance)
      if name && !name.empty?
        old_instances = class_type.where(name: name).not_deprecated
        old_instances = nil if (old_instances.count > 1) && (old_instances.first == new_instance)
      end

      yield

      if name && !name.empty? && old_instances && !new_instance.deprecated?
        new_instance.save
        old_instances.each { |old_instance| old_instance.deprecate_with(new_instance) if old_instance != new_instance }
      end
    end

    def initialize(step_type, quads, graph_conditions, graph_consequences)
      @quads = quads
      @graph_conditions = graph_conditions
      @graph_consequences = graph_consequences
      @c_groups = {}
      @c_groups_cardinalities = {}

      @step_type = step_type || StepType.create(name: name_for_step_type)
      self
        .class
        .deprecate_class_by_name(StepType, name_for_step_type, @step_type) do
          @step_type.assign_attributes(config_for_step_type)
          if activity_type
            @step_type.activity_types << activity_type unless @step_type.activity_types.include?(activity_type)
          end
        end
    end

    def conditions
      @conditions ||= @quads.select { |quad| quad.last === @graph_conditions }
    end

    def actions
      @actions ||= sort_created_assets_first(@quads.select { |quad| quad.last === @graph_consequences })
    end

    def sort_created_assets_first(list)
      list.sort do |a, b|
        if fragment(a[1]) == 'createAsset'
          -1
        elsif fragment(b[1]) == 'createAsset'
          1
        else
          fragment(a[1]) <=> fragment(b[1])
        end
      end
    end

    def fragment(k)
      k.try(:fragment) || (k.try(:name) || k).to_s.gsub(/.*#/, '').gsub(/_[0-9][0-9][0-9][0-9][0-9][0-9].*$/, '')
    end

    def self.fragment(k)
      k.try(:fragment) || (k.try(:name) || k).to_s.gsub(/.*#/, '').gsub(/_[0-9][0-9][0-9][0-9][0-9][0-9].*$/, '')
    end

    def condition_group_for(node)
      c_groups[fragment(node)]
    end

    def store_condition_group(condition_group)
      c_groups[condition_group.name] = condition_group
    end

    def find_or_create_condition_group_for(node, params)
      if condition_group_for(node)
        condition_group_for(node)
      else
        params[:name] = fragment(fragment(node))
        store_condition_group(ConditionGroup.create(params))
      end
    end

    def keep_selected_list
      actions
        .select { |quad| fragment(quad[1]) == 'unselectAsset' }
        .map do |q|
          q[2].class == RDF::Node ? fragment(@quads.select { |_k, _p, _v, g| g == q[2] }.flatten[0]) : fragment(q[2])
        end
        .flatten
    end

    def check_keep_selected_asset(node)
      list = keep_selected_list
      !list.include?(fragment(node))
    end

    def update_condition_group(condition_group, p, v)
      if fragment(p) == 'maxCardinality'
        # Once we have the condition group, we update cardinality
        @c_groups_cardinalities[fragment(p)] = fragment(v)
        condition_group.update(cardinality: fragment(v))
      else
        # or we add the new condition
        object_condition_group = condition_group_for(v)

        # if (!object_condition_group.nil? && object_condition_group.conditions.empty? && (fragment(v)[0] != '_'))
        #  object_condition_group = nil
        # end
        Condition.create(
          {
            predicate: fragment(p),
            object: fragment(v),
            condition_group_id: condition_group.id,
            object_condition_group: object_condition_group
          }
        )
      end
    end

    def is_wildcard?(v)
      (fragment(v)[0] == ('_'))
    end

    def build_condition_groups
      # Left side of the rule
      conditions.each do |k, _p, _v, _g|
        # Finds the condition group (or creates it)
        condition_group =
          find_or_create_condition_group_for(k, { step_type: @step_type, keep_selected: check_keep_selected_asset(k) })
      end
      cgr = []
      conditions.each do |k, p, v, _g|
        if is_wildcard?(v)
          vcgroup =
            find_or_create_condition_group_for(
              v,
              { step_type: @step_type, keep_selected: check_keep_selected_asset(v) }
            )
          cgr.push(condition_group_for(v))
        end

        # After reading all condition groups we will be able to recognize
        # the condition groups of the objects in the triple
        update_condition_group(condition_group_for(k), p, v)
        cgr.push(condition_group_for(k))
      end

      # Remove reference to step type for condition groups without conditions
      cgr.each { |cg| cg.update(step_type: nil) if cg.conditions.count == 0 }
    end

    def self.activity_type_name(quads)
      quads.select { |quad| fragment(quad[1]) == 'activityTypeName' }.flatten[2].to_s
    end

    def activity_type_name
      self.class.activity_type_name(@quads)
    end

    def self.activity_type=(value)
      @activity_type = value
    end

    def self.activity_type(quads)
      @activity_type ||= ActivityType.new(name: activity_type_name(quads)) unless activity_type_name(quads).empty?
    end

    def activity_type
      self.class.activity_type(@quads)
    end

    def config_for_step_type
      config = {}
      config[:name] = name_for_step_type if name_for_step_type
      config[:connect_by] = connect_by if connect_by
      config[:step_template] = step_template if step_template
      config[:step_action] = step_action if step_action
      config[:n3_definition] = nil
      config
    end

    def name_for_step_type
      value = actions.select { |quad| fragment(quad[1]) == 'stepTypeName' }.flatten[2]
      fragment(value) unless value.nil?
    end

    def connect_by
      value = actions.select { |quad| fragment(quad[1]) == 'connectBy' }.flatten[2]
      fragment(value) unless value.nil?
    end

    def step_template
      value = actions.select { |quad| fragment(quad[1]) == 'stepTemplate' }.flatten[2]
      fragment(value) unless value.nil?
    end

    def step_action
      value = actions.select { |quad| fragment(quad[1]) == 'stepAction' }.flatten[2]
      fragment(value) unless value.nil?
    end

    def execute
      build_condition_groups
      build_actions
    end

    def build_actions
      # Right side of the rule
      actions.each do |_k, p, v, _g|
        action = fragment(p)
        unless v.literal?
          @quads
            .select { |quad| quad.last == v }
            .each do |k, p, v, _g|
              # Updates cardinality for the condition group
              if fragment(p) == 'maxCardinality'
                @c_groups_cardinalities[fragment(k)] = fragment(v)
                if @c_groups[fragment(k)]
                  @c_groups[fragment(k)].update(cardinality: @c_groups_cardinalities[fragment(k)])
                end
                next
              end

              # Creates condition groups from the subjects of the actions
              # side of the rules
              if @c_groups[fragment(k)].nil?
                @c_groups[fragment(k)] =
                  ConditionGroup.create(
                    {
                      cardinality: @c_groups_cardinalities[fragment(k)],
                      name: fragment(k),
                      keep_selected: check_keep_selected_asset(fragment(k))
                    }
                  )
              end

              # Creates condition groups from the objects of the actions side
              object_condition_group_id = nil
              if c_groups[fragment(v)]
                object_condition_group_id = c_groups[fragment(v)].id
              else
                if v.class.name == 'RDF::Query::Variable'
                  if c_groups[fragment(v)].nil?
                    c_groups[fragment(v)] =
                      ConditionGroup.create(
                        cardinality: @c_groups_cardinalities[fragment(v)],
                        name: fragment(v),
                        keep_selected: check_keep_selected_asset(fragment(v))
                      )
                  end
                  object_condition_group_id = c_groups[fragment(v)].id
                end
              end
              Action.create(
                {
                  action_type: action,
                  predicate: fragment(p),
                  object: fragment(v),
                  step_type_id: @step_type.id,
                  subject_condition_group_id: @c_groups[fragment(k)].id,
                  object_condition_group_id: object_condition_group_id
                }
              )
              if action == 'unselectAsset'
                Condition.create(
                  { predicate: fragment(p), object: fragment(v), condition_group_id: @c_groups[fragment(k)].id }
                )
              end
            end
        end
      end
    end
  end
end
