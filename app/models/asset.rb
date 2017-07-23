require 'sequencescape_client'
require 'barcode'
require 'date'

require 'pry'

class Asset < ActiveRecord::Base
  include Lab::Actions
  include Printables::Instance
  extend Asset::Import
  include Asset::Export


  alias_attribute :name, :uuid 

  has_many :facts, :dependent => :delete_all
  has_and_belongs_to_many :asset_groups
  has_many :steps, :through => :asset_groups

  before_save :generate_uuid
  #before_save :generate_barcode


  def update_compatible_activity_type
    ActivityType.visible.all.each do |at|
      activity_types << at if at.compatible_with?(self)
    end
  end

  has_many :operations

  has_many :activity_type_compatibilities
  has_many :activity_types, :through => :activity_type_compatibilities

#:class_name => 'Action', :foreign_key => 'subject_condition_group_id'
  #has_many :activities_started, -> {joins(:steps)}, :class_name => 'Activity'
  has_many :activities_started, -> { uniq }, :through => :steps, :source => :activity, :class_name => 'Activity'
  has_many :activities, :through => :asset_groups

  scope :with_fact, ->(predicate, object) {
    joins(:facts).where(:facts => {:predicate => predicate, :object => object})
  }

  scope :currently_changing, ->() {
    joins(:asset_groups, :steps).where(:steps => {:state => 'running'})
  }

  scope :with_field, ->(predicate, object) {
    where(predicate => object)
  }

  scope :with_predicate, ->(predicate) {
    joins(:facts).where(:facts => {:predicate => predicate})
  }

  scope :for_activity_type, ->(activity_type) {
    joins(:activities_started).joins(:facts).where(:activities => { :activity_type_id => activity_type.id}).order("activities.id")
  }

  scope :not_started, ->() {
    with_fact('is','NotStarted')
  }

  scope :started, ->() {
    with_fact('is','Started')
  }

  scope :compatible2_with_activity_type, ->(activity_type) {
    joins(:facts).
    joins("right outer join conditions on conditions.predicate=facts.predicate and conditions.object=facts.object").
    joins("inner join condition_groups on condition_groups.id=condition_group_id").
    joins("inner join step_types on step_types.id=condition_groups.step_type_id").
    joins("inner join activity_type_step_types on activity_type_step_types.step_type_id=step_types.id").
    where("activity_type_step_types.activity_type_id = ?", activity_type)
  }

  scope :compatible_with_activity_type, ->(activity_type) {
    st = activity_type.step_types.select do |st|
      st.condition_groups.select{|cg| cg.conditions.any?{|c| c.predicate == 'is' && c.object == 'NotStarted'}}
    end.first
    st_checks = [st.id, st.condition_groups.map(&:id)]

    joins(:facts).
    joins("right outer join conditions on conditions.predicate=facts.predicate and conditions.object=facts.object").
    joins("inner join condition_groups on condition_groups.id=condition_group_id").
    joins("inner join step_types on step_types.id=condition_groups.step_type_id").
    joins("inner join activity_type_step_types on activity_type_step_types.step_type_id=step_types.id").
    where("activity_type_step_types.activity_type_id = ? and activity_type_step_types.step_type_id = ? and condition_groups.id in (?)", activity_type, st_checks[0], st_checks[1])
  }


  #def self.assets_compatible_with_activity_type(assets, activity_type)
  # scope :assets_compatible_with_activity_type, ->(assets, activity_type) {
  #   select do |asset|
  #     activity_type.step_types.any? do |s|
  #       s.condition_groups.all? do |cg|
  #         cg.compatible_with?(asset)
  #       end
  #     end
  #   end
  # }

  def add_facts(list, position=nil, &block)
    ActiveRecord::Base.transaction do |t|
      list = [list].flatten
      list.each do |fact|
        unless has_fact?(fact)
          if ((fact.position.nil?) || (fact.position == position))
            facts << fact
            if fact.predicate == 'barcode'
              update_attributes(:barcode => fact.object)
            end
            if fact.predicate == 'uuid'
              update_attributes(:uuid => fact.object)
            end            
            yield fact if block_given?
          end
        end
      end
    end
    touch unless new_record?
  end

  def remove_facts(list, &block)
    ActiveRecord::Base.transaction do |t|
      list = [list].flatten
      list.each do |fact|
        yield fact if block_given?
        if fact.object_asset
          facts.where(predicate: fact.predicate, object_asset: fact.object_asset).each(&:destroy)
        elsif fact.object
          facts.where(predicate: fact.predicate, object: fact.object).each(&:destroy)
        end
      end
    end
  end

  def add_fact(predicate, object, step=nil)
    fact = {predicate: predicate, literal: object.kind_of?(Asset)}
    fact[:literal] ? fact[:object_asset] = object : fact[:object] = object
    add_facts([Fact.create(fact)], nil)
  end

  def add_operations(list, step, action_type = 'addFacts')
    list.each do |fact|
      Operation.create!(:action_type => action_type, :step => step,
        :asset=> self, :predicate => fact.predicate, :object => fact.object)    
    end
  end

  def remove_operations(list, step)
    list.each do |fact|
      Operation.create!(:action_type => 'removeFacts', :step => step,
        :asset=> self, :predicate => fact.predicate, :object => fact.object)    
    end
  end


  def short_description
    "#{aliquot_type} #{class_type} #{barcode.blank? ? '#' : barcode}".chomp
  end

  def aliquot_type
    f = facts.with_predicate('aliquotType').first
    f ? f.object : ""
  end

  def relation_id
    uuid
  end

  def has_literal?(predicate, object)
    facts.any?{|f| f.predicate == predicate && f.object == object}
  end

  def has_predicate?(predicate)
    facts.any?{|f| f.predicate == predicate}
  end  

  def has_fact?(fact)
    facts.any? do |f|
      if f.object.nil?
        ((fact.predicate == f.predicate) && (fact.object_asset == f.object_asset) &&
          (fact.to_add_by == f.to_add_by) && (fact.to_remove_by == f.to_remove_by))
      else
        other_conds=true
        if fact.respond_to?(:to_add_by)
          other_conds = (fact.to_add_by == f.to_add_by) && (fact.to_remove_by == f.to_remove_by)
        end
        ((fact.predicate == f.predicate) && (fact.object == f.object) && other_conds)
      end
    end
  end

  def self.assets_for_queries(queries)
    queries.map do |query|
      if Asset.first && Asset.first.has_attribute?(query.predicate)
        Asset.with_field(query.predicate, query.object)
      else
        Asset.with_fact(query.predicate, query.object)
      end
    end.reduce([]) do |memo, result|
      if memo.empty?
        result
      else
        result & memo
      end
    end
  end


  def facts_to_s
    facts.each do |fact|
      render :partial => fact
    end
  end

  def object_value(fact)
    fact.object || fact.object_asset.uuid
  end

  def condition_groups_init
    obj = {}
    obj[barcode] = { :template => 'templates/asset_facts'}
    obj[barcode][:facts]=facts.map do |fact|
          {
            :cssClasses => '',
            :name => uuid,
            :actionType => 'createAsset',
            :predicate => fact.predicate,
            :object_reference => fact.object_asset_id,
            :object_label => fact.object_label,
            :object => object_value(fact)
          }
        end

    obj
  end

  def facts_for_reasoning
    [facts, Fact.as_object(asset)].flatten
  end

  def reasoning!(&block)
    num_iterations = 0
    current_facts = facts_for_reasoning
    assets = current_facts.pluck(:asset)
    done = false
    while !done do

      previous_facts = current_facts.clone

      yield assets

      current_facts = facts_for_reasoning

      if ((current_facts == previous_facts) || (num_iterations >10))
        done = true
      end
      num_iterations += 1
    end
    raise 'Too many iterations while reasoning...' if num_iterations > 10
  end

  def generate_uuid
    update_attributes(:uuid => SecureRandom.uuid) if uuid.nil?
  end

  def generate_barcode(i)
    save
    if barcode.nil?
      update_attributes(:barcode => Barcode.calculate_barcode(Rails.application.config.barcode_prefix,self.id))
    end
    # if barcode.nil?
    #   generated_barcode = Barcode.calculate_barcode(Rails.application.config.barcode_prefix,Asset.count+i)
    #   if find_by(:barcode =>generated_barcode).nil?
    #     update_attributes(:barcode => generated_barcode) 
    #   else
        
    #   end
    # end
  end

  def attrs_for_sequencescape(traversed_list = [])
    hash = facts.map do |fact|
      if fact.literal?
        [fact.predicate,  fact.object_value]
      else
        if traversed_list.include?(fact.object_value)
          [fact.predicate, fact.object_value.uuid]
        else
          traversed_list.push(fact.object_value)
          [fact.predicate, fact.object_value.attrs_for_sequencescape(traversed_list)]
        end
      end
    end.reduce({}) do |memo, list|
      predicate,object = list
      if memo[predicate] || memo[predicate.pluralize]
        # Updates name of list to pluralized name
        unless memo[predicate].kind_of? Array
          memo[predicate.pluralize] = [memo[predicate]]
          memo = memo.except!(predicate) if predicate != predicate.pluralize
        end
        memo[predicate.pluralize].push(object)
      else
        memo[predicate] = object
      end
      memo
    end
    #return {:uuid => uuid, :barcode => { :prefix => 'SE', :number => 14 }}
    hash
  end

  def method_missing(sym, *args, &block)
    list_facts = facts.with_predicate(sym.to_s.singularize)
    return list_facts.map(&:object_value) unless list_facts.empty?
    super(sym, *args, &block)
  end

  def respond_to?(sym, include_private = false)
    (!facts.with_predicate(sym.to_s.singularize).empty? || super(sym, include_private))
  end

  def study_and_barcode
    [study_name, barcode_sequencescaped].join(' ')
  end

  def barcode_sequencescaped
    ean13 = barcode.rjust(13, '0')
    ean13.slice!(0,3)
    ean13.slice!(ean13.length-3,3)
    ean13.to_i
  end

  def study_name
    if has_predicate?('study_name')
      return facts.with_predicate('study_name').first.object
    end
    return ''
  end

  def printable_object(username = 'unknown')
    return nil if barcode.nil?
    if ((class_type=='Plate')||(class_type=='TubeRack'))
      return {
        :label => {
          :barcode => barcode,
          :top_left => DateTime.now.strftime('%d/%b/%y'),
          :top_right => info_line, #username,
          :bottom_right => study_and_barcode,
          :bottom_left => Barcode.barcode_to_human(barcode) || barcode,
          #:top_line => Barcode.barcode_to_human(barcode) || barcode,
          #:bottom_line => bottom_line 
        }
      } 
    end
    return {:label => {
      :barcode => barcode,
      :barcode2d => barcode,      
      :top_line => Barcode.barcode_to_human(barcode) || barcode,
      :bottom_line => info_line 
      }
    }
  end

  def position_value
    val = facts.map(&:position).compact.first
    val.nil? ? "" : "_#{(val.to_i+1).to_s}"
  end

  def info_line
    ["#{class_name}", "#{aliquot}","#{position_value}"].join(' ').strip
  end

  def class_name
    purposes_facts = facts.with_predicate('purpose')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end

  def aliquot
    purposes_facts = facts.with_predicate('aliquotType')
    if purposes_facts.count > 0
      return purposes_facts.first.object
    end
    return ''
  end


  def first_value_for(predicate)
    facts.with_predicate(predicate).first.object
  end

  def position_name_for_symphony
    str = first_value_for('location')
    [str[0], str[1..-1]].join(':')
  end

  def position_index_for_symphony
    str = first_value_for('location')
    (str[1..-1] * 12) + (str[0].ord - 'A'.ord)
  end

  def asset_description
    names = facts.with_predicate('a').map(&:object).join(' ')
    types = facts.with_predicate('aliquotType').map(&:object).join(' ')
    return names + ' ' + types
  end

  def self.class_type(facts)
    class_types = facts.select{|f| f[:predicate] == 'a'}.map(&:object)
    return 'TubeRack' if class_types.include?('TubeRack')
    return 'Plate' if class_types.include?('Plate')
    return 'Tube' if class_types.include?('Tube')
    return 'SampleTube' if class_types.include?('SampleTube')
    return facts.select{|f| f[:predicate] == 'a'}.first.object if facts.select{|f| f[:predicate] == 'a'}.first
    return ""
  end

  def class_type
    Asset.class_type(facts)
  end


  def contains_location?(location)
    facts.with_predicate('contains').any? do |f|
      f.object_asset.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def assets_at_location(location)
    facts.with_predicate('contains').map(&:object_asset).select do |a|
      a.facts.with_predicate('location').map(&:object).include?(location)
    end
  end

  def remove_from_parent(parent)
    facts.with_predicate('parent').select{|f| f.object_asset==parent}.each(&:destroy)
    facts.with_predicate('location').each(&:destroy)
  end


  def duplicated_tubes_validation
    contained_assets = facts.with_predicate('contains').map(&:object_asset)
    duplicated = contained_assets.select do |element|
      element.facts.with_predicate('location').count > 1
    end.uniq
    unless duplicated.empty?
      return duplicated.map do |duplicate_tube|
        "The tube #{duplicated_tube.barcode} is duplicated in the layout"
      end
    end
    return []
  end

  def more_than_one_aliquot_type_validation
    if facts.with_predicate('contains').map(&:object_asset).map do |well|
      well.facts.with_predicate('aliquotType').map(&:object)
      end.flatten.uniq.count > 1
      return ['More than one aliquot type in the same rack']
    end
    return []
  end

  def barcode_type
    btypes = facts.with_predicate('barcodeType')
    return 'ean13' if btypes.empty?
    btypes.first.object.downcase
  end

  def validate_rack_content
    errors=[]
    errors.push(more_than_one_aliquot_type_validation)
    #errors.push(duplicated_tubes_validation)
    errors
  end

  def is_sequencescape_plate?
    has_literal?('barcodeType', 'SequencescapePlate')
  end

  def to_n3
    #facts.map do |f|
    #  "<#{uuid}> :#{f.predicate} " + (f.object_asset.nil? ? "\"#{f.object}\"" : "<#{f.object_asset.uuid}>") +" .\n"
    #end.join('')
    render :n3
  end
end
