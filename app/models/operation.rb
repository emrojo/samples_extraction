class Operation < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :step
  belongs_to :asset
  belongs_to :object_asset, class_name: 'Asset'
  belongs_to :action
  belongs_to :activity

  scope :for_presenting, -> { includes(:asset, :action) }
  scope :with_asset, -> { where.not(asset_id: nil) }

  def object_value
    object || object_asset
  end

  def opposites
    {
      add_facts: :remove_facts,
      remove_facts: :add_facts,
      create_assets: :delete_assets,
      delete_assets: :create_assets,
      create_asset_groups: :delete_asset_groups,
      delete_asset_groups: :create_asset_groups,
      add_assets: :remove_assets,
      remove_assets: :add_assets
    }
  end

  def action_type_for_option(option)
    if option == :remake
      action_type.underscore.to_sym
    elsif option == :cancel
      opposites[action_type.underscore.to_sym]
    end
  end

  def generate_changes_for(option_name, updates = nil)
    updates ||= FactChanges.new
    type = action_type_for_option(option_name)
    if type == :add_facts
      updates.add(self.asset, self.predicate, object_value)
    elsif type == :remove_facts
      updates.remove_where(self.asset, self.predicate, object_value)
    elsif type == :create_assets
      updates.create_assets([object])
    elsif type == :delete_assets
      updates.delete_assets([object])
    elsif type == :add_assets
      updates.add_assets([[AssetGroup.find_by(uuid: object), [self.asset]]])
    elsif type == :remove_assets
      updates.remove_assets([[AssetGroup.find_by(uuid: object), [self.asset]]])
    elsif type == :create_asset_groups
      updates.create_asset_groups([object])
    elsif type == :delete_asset_groups
      updates.delete_asset_groups([object])
    end
    updates
  end
end
