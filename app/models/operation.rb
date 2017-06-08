# frozen_string_literal: true
class Operation < ApplicationRecord
  belongs_to :step
  belongs_to :asset
  belongs_to :object_asset, class_name: 'Asset'
  belongs_to :action
  belongs_to :activity

  scope :for_presenting, ->() { includes(:asset, :action, :object_asset) }

  def action_type
    return action.action_type if action
    attributes['action_type']
  end

  def opposites
    {
      add_facts: :remove_facts, remove_facts: :add_facts,
      create_asset: :remove_facts, delete_asset: :add_facts
    }
  end

  def synonims
    {
      add_facts: :add_facts, remove_facts: :remove_facts,
      create_asset: :add_facts, delete_asset: :remove_facts
    }
  end

  def cancel
    send(opposites[action_type.underscore.to_sym].to_s)
    update_attributes(cancelled?: true)
  end

  def remake
    send(synonims[action_type.underscore.to_sym].to_s)
    update_attributes(cancelled?: false)
  end

  def add_facts
    asset.add_facts(Fact.new(predicate: predicate, object: object, object_asset: object_asset))
    asset.touch
  end

  alias create_asset add_facts

  def remove_facts
    asset.remove_facts(Fact.new(predicate: predicate, object: object, object_asset: object_asset))
    asset.touch
  end

  alias delete_asset remove_facts
end
