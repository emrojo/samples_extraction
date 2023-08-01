class Step < ApplicationRecord # rubocop:todo Style/Documentation
  self.inheritance_column = :sti_type

  attr_accessor :wildcard_values

  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations
  has_many :step_messages
  has_many :assets, through: :asset_group
  has_many :assets_affected, -> { distinct }, through: :operations, class_name: 'Asset', source: :asset
  has_many :asset_groups_affected,
           -> { distinct },
           through: :assets_affected,
           class_name: 'AssetGroup',
           source: :asset_groups
  has_many :activities_affected,
           -> { distinct },
           through: :asset_groups_affected,
           class_name: 'Activity',
           source: :activity_owner
  belongs_to :created_asset_group, class_name: 'AssetGroup', foreign_key: 'created_asset_group_id'
  belongs_to :next_step, class_name: 'Step', foreign_key: 'next_step_id'

  serialize :printer_config

  scope :running_with_asset,
        ->(asset) { includes(:assets).where(asset_groups_assets: { asset_id: asset.id }, state: 'running') }
  scope :for_assets, ->(assets) { joins(asset_group: :assets).where(asset_groups_assets: { asset_id: assets }) }
  scope :for_step_type, ->(step_type) { where(step_type: step_type) }
  scope :include_messages, -> { includes(:step_messages) }

  delegate :report_error, to: :activity

  include Deprecatable
  include Steps::QueueableJob
  include Steps::Job
  include Steps::Task
  include Steps::Compatible
  include Steps::Cancellable
  include Steps::Deprecatable
  include Steps::Retryable
  include Steps::Stoppable
  include Steps::State
  include Steps::WebsocketEvents

  def set_errors(errors)
    ActiveRecord::Base.transaction do
      step_messages.each(&:destroy)
      errors.each { |error| step_messages.create(step_id: self.id, content: error) }
    end
    wss_event
  end
end
