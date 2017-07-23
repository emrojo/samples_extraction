require 'support_n3'

class StepType < ActiveRecord::Base

  before_update :remove_previous_conditions
  after_save :create_next_conditions, :unless => :for_reasoning?

  has_many :activity_type_step_types, dependent: :destroy
  has_many :activity_types, :through => :activity_type_step_types
  has_many :condition_groups, dependent: :destroy
  has_many :actions, dependent: :destroy

  has_many :action_subject_condition_groups, :through => :actions, :source => :subject_condition_group
  has_many :action_object_condition_groups, :through => :actions, :source => :object_condition_group


  include Deprecatable

  scope :with_template, ->() { where('step_template is not null')}

  scope :for_reasoning, ->() { where(:for_reasoning => true)}

  scope :not_for_reasoning, ->() { where(:for_reasoning => false) }

  def after_deprecate
    superceded_by.activity_types << activity_types
    update_attributes!(:activity_types => [])
  end


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

  def all_step_templates
    #Dir["app/views/step_types/step_templates/*"].concat([''])
    ['', 'transfer_tube_to_tube', 'upload_file_step']
    Dir["app/views/step_types/step_templates/*"].map do |s|
      name = File.basename(s)
      name.gsub!(/^_/, '')
      name.gsub!(/\.html\.erb$/, '')
      name
    end.concat([''])
  end

  def condition_groups_init
    cgroups = condition_groups.reduce({}) do |memo, condition_group|
      name = condition_group.name || "a#{condition_group.id}"
      memo[name] = {
        :cardinality => condition_group.cardinality,
        :keepSelected => condition_group.keep_selected,
        :facts =>  condition_group.conditions.map do |condition|
          {
            :cssClasses => fact_css_classes['checkFacts'],
            :name => name,
            :actionType => 'checkFacts',
            :predicate => condition.predicate,
            :object => condition.object
          }
        end
      }
      memo
    end
    agroups = actions.reduce(cgroups) do |memo, action|
      name = action.subject_condition_group.name || "a#{action.subject_condition_group.id}"
      memo[name]={
        :facts => [],
        :cardinality => action.subject_condition_group.cardinality,
        :keepSelected => action.subject_condition_group.keep_selected
      } unless memo[name]
      memo[name][:facts].push({
          :cssClasses => fact_css_classes[action.action_type],
          :name => name,
          :actionType => action.action_type,
          :predicate => action.predicate,
          :object => action.object
        })
      memo
    end
    agroups.to_json
  end

  def create_next_conditions
    unless n3_definition.nil?
      SupportN3::parse_string(n3_definition, {}, self)
    end
  end

  def remove_previous_conditions
    condition_groups.each do |condition_group|
      condition_group.conditions.each(&:destroy)
      condition_group.destroy
    end
    actions.each do |action|
      action.update_attributes(:step_type_id => nil)
    end
  end

  def position_for_assets_by_condition_group(assets)
    all_cgroups = {}
    Hash[condition_group_classification_for(assets).map do |asset, cgroups|
      [asset, Hash[cgroups.map do |cgroup|
        all_cgroups[cgroup] = 0 if all_cgroups[cgroup].nil?
        position = all_cgroups[cgroup]
        all_cgroups[cgroup] = all_cgroups[cgroup] + 1
        [cgroup, position]
      end]]
    end]
  end

  def condition_group_classification_for(assets, checked_condition_groups=[], wildcard_values={})
    related_assets = []
    h = Hash[assets.map{|asset| [asset, condition_groups_for(asset, related_assets, [], wildcard_values)]}]
    related_assets.each do |a|
      h[a]= condition_groups_for(a, [], checked_condition_groups, wildcard_values)
    end
    h
  end

  def every_condition_group_satisfies_cardinality(classification)
    # http://stackoverflow.com/questions/10989259/swapping-keys-and-values-in-a-hash
    inverter_classification = classification.each_with_object({}) do |(k,v),o|
      v.each do |cg|
        (o[cg]||=[])<<k
      end
    end
    inverter_classification.keys.all? do |condition_group|
      condition_group.cardinality.nil? || (condition_group.cardinality==0) ||
        (condition_group.cardinality >= inverter_classification[condition_group].length)
    end
  end

  def every_condition_group_has_at_least_one_asset?(classification, cgroups = nil)
    cgroups = condition_groups if cgroups.nil?
    (classification.values.flatten.uniq.length == cgroups.length)
  end

  def every_asset_has_at_least_one_condition_group?(classification)
    (classification.values.all? do |condition_group|
      ([condition_group].flatten.length>=1)
    end)
  end

  def every_required_asset_is_in_classification?(classification, required_assets)
    return true if required_assets.nil?
    required_assets.all?{|asset| !classification[asset].empty?}
  end

  def compatible_with?(assets, required_assets=nil, checked_condition_groups=[], wildcard_values={})
    assets = Array(assets).flatten
    # Every asset has at least one condition group satisfied
    classification = condition_group_classification_for(assets, checked_condition_groups, wildcard_values)
    compatible = every_condition_group_satisfies_cardinality(classification) &&
    every_condition_group_has_at_least_one_asset?(classification) &&
      every_asset_has_at_least_one_condition_group?(classification) &&
      every_required_asset_is_in_classification?(classification, required_assets)
    return true if compatible
    return false
  end

  def condition_groups_for(asset, related_assets = [], checked_condition_groups=[], wildcard_values={})
    condition_groups.select do |condition_group|
      condition_group.compatible_with?([asset].flatten, related_assets, checked_condition_groups, wildcard_values)
      #condition_group.conditions_compatible_with?(asset, related_assets)
    end
  end

  def actions_for_condition_group(condition_group)
  end

  def actions_for(assets)
    #condition_group_classification_for(assets)
  end

  def explain(assets)

  end

  def classification_for(assets, cgroups)
    assets.reduce({}) do |memo, asset|
      memo[asset] = cgroups.select do |condition_group|
        condition_group.compatible_with?([asset].flatten)
      end
      memo
    end    
  end

  def check_dependency_compatibility_for(asset, condition_group, assets)
    check_cgs = condition_groups.select do |cg| 
      cg.conditions.select{|c| c.object_condition_group == condition_group}.count > 0 
    end
    return true if check_cgs.empty?
    ancestors = assets.select{|a| a.facts.any?{|f| f.object_asset == asset}}.uniq
    return true if ancestors.empty?

    classification = classification_for(ancestors, check_cgs)

    compatible = every_condition_group_satisfies_cardinality(classification) &&
    every_condition_group_has_at_least_one_asset?(classification, check_cgs) &&
      every_asset_has_at_least_one_condition_group?(classification)
    return true if compatible
    return false
  end

  def to_n3
    render :n3
    # return n3_definition if condition_groups.empty? || actions.empty?
    # ["{",
    # condition_groups.map(&:conditions).flatten.map do |c|
    #   obj = c.object
    #   obj = "\"#{obj}\"" unless c.object_condition_group
    #   if c.object_condition_group
    #     "\t?#{c.condition_group.name} :#{c.predicate} ?#{c.object_condition_group.name} ."
    #   else
    #     "\t?#{c.condition_group.name} :#{c.predicate} #{obj} ." 
    #   end
    # end, "} => {",
    # actions.map do |a|
    #   obj = a.object
    #   obj = "\"#{obj}\"" unless a.object_condition_group
    #   if a.object_condition_group
    #     "\t:step :#{a.action_type} {?#{a.subject_condition_group.name} :#{a.predicate} ?#{a.object_condition_group.name}. } ."
    #   else
    #     "\t:step :#{a.action_type} {?#{a.subject_condition_group.name} :#{a.predicate} #{obj}. } ."
    #   end
    # end, 
    # name ? "\t:step :stepTypeName \"#{name}\" ." : '',
    # connect_by ? "\t:step :connectBy \"#{connect_by}\" ." : nil,
    # "}."].flatten.compact.join("\n")
  end

end
