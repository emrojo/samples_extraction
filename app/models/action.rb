class Action < ApplicationRecord
  belongs_to :subject_condition_group, :class_name => 'ConditionGroup'
  belongs_to :object_condition_group, :class_name => 'ConditionGroup'

  belongs_to :step_type

  @@TYPES = [:checkFacts, :addFacts, :removeFacts]

  def self.types
    @@TYPES
  end

  # Given the current action (that defines a relation between 2 conditional groups)
  # and the list of assets classified into 2 groups: sources or destinations, this method
  # will generate a list of pairs [source, destination] that can be connected.
  def each_connected_asset(sources, destinations, wildcard_values = {}, &block)
    unless (wildcard_values.nil? || wildcard_values.empty?)
      if (object_condition_group)
        if (wildcard_values[object_condition_group.id])
          return sources.each_with_index do |source, index|
            if wildcard_values[object_condition_group.id][source.id]
              yield source, wildcard_values[object_condition_group.id][source.id].first
            else
              values_for_wildcard = wildcard_values[object_condition_group.id].values.flatten
              if (values_for_wildcard.length == 1)
                yield source, values_for_wildcard[0]
              else
                yield source, values_for_wildcard[index]
              end
            end
          end
        else
          value_for = wildcard_values.values.first
          return sources.each do |s|
            destinations.each do |d|
              if (value_for[s.id] && value_for[d.id])
                yield s,d if (value_for[s.id] == value_for[d.id])
              else
                yield s,d
              end
            end
          end
        end
      end
    end
    if step_type.connect_by == 'position'
      sources.zip(destinations).each { |s,d| yield s,d if d }
    else
      sources.each do |s|
        destinations.each do |d|
          yield s,d
        end
      end
    end
  end

  def sources(asset_group)
    asset_group.classified_by_condition_group(subject_condition_group)
  end

  def destinations(asset_group)
    if object_condition_group.nil?
      sources(asset_group).length.times.map { object }
    else
      asset_group.classified_by_condition_group(object_condition_group)
    end
  end

  def run(asset_group, wildcard_values = {})
    FactChanges.new.tap do |updates|
      if action_type == 'createAsset'
        if (asset_group.classified_by_condition_group(subject_condition_group).length > 0)
          assets = asset_group.classified_by_condition_group(subject_condition_group)
        else
          assets = num_assets_to_create(asset_group).times.map { Asset.new }
          updates.create_assets(assets)
          updates.add_assets([[asset_group, assets]])
          #asset_group.assets << assets


          updates.create_asset_groups(["?#{subject_condition_group.name}"])
          updates.add_assets([["?#{subject_condition_group.name}", assets]])

          asset_group.classify_assets_in_condition_group(assets, subject_condition_group)
        end
        destinations = destinations(asset_group)
        assets.each do |asset|
          each_connected_asset(assets, destinations, wildcard_values) do |s, d|
            updates.add(s, predicate, d)
          end
        end
      elsif action_type == 'createGroup'
        updates.create_asset_groups([object])
      elsif action_type == 'deleteGroup'
        updates.delete_asset_groups([object])
      elsif action_type == 'addAsset'
        updates.add_assets([[object, [sources(asset_group)]]])
      elsif action_type == 'removeAsset'
        updates.remove_assets([[object, [sources(asset_group)]]])
      elsif action_type == 'deleteAsset'
        updates.delete_assets([object])
      elsif action_type == 'selectAsset'
        updates.add_assets([[asset_group, sources(asset_group)]])
      elsif action_type == 'unselectAsset'
        updates.remove_assets([[asset_group, sources(asset_group)]])
      else
        each_connected_asset(sources(asset_group), destinations(asset_group), wildcard_values) do |source, destination|
          if action_type=='addFacts'
            updates.add(source, predicate, destination)
          elsif action_type == 'removeFacts'
            updates.remove_where(source, predicate, destination)
          end
        end
      end
    end
  end

  def num_assets_to_create(asset_group)
    return asset_group.assets.count unless (subject_condition_group.cardinality) && (subject_condition_group.cardinality!=0)
    return subject_condition_group.cardinality
    #return [[asset_group.assets.count, subject_condition_group.cardinality].min, 1].max
  end

end
