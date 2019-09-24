require 'sequencescape_client'
require 'date'
require 'pry'
require 'validators/plate/single_aliquot_validator'
require 'validators/plate/duplicated_tubes_validator'

class Asset < ActiveRecord::Base
  include Uuidable
  include Printables::Instance
  include Assets::Import
  include Assets::Export
  include Assets::FactsManagement
  include Assets::TractionFields
  include Assets::Barcodeable
  include Assets::Fields

  validates_with Validators::Plate::SingleAliquotValidator
  validates_with Validators::Plate::DuplicatedTubesValidator, if: :kind_of_plate?

  alias_attribute :name, :uuid

  has_one :uploaded_file
  has_many :facts, :dependent => :delete_all
  has_many :asset_groups_assets, dependent: :destroy
  has_many :asset_groups, through: :asset_groups_assets
  has_many :steps, :through => :asset_groups
  has_many :activities_affected, -> { distinct }, through: :asset_groups, class_name: 'Activity', source: :activity_owner
  has_many :operations, dependent: :nullify
  has_many :activity_type_compatibilities
  has_many :activity_types, :through => :activity_type_compatibilities
  has_many :activities, -> { distinct }, :through => :steps

  scope :currently_changing, ->() {
    joins(:asset_groups, :steps).where(:steps => {:state => 'running'})
  }

  scope :for_activity_type, ->(activity_type) {
    joins(:activities).where(:activities => {
      :activity_type_id => activity_type.id
    })
  }

  scope :not_started, ->() {
    with_fact('is','NotStarted')
  }

  scope :started, ->() {
    with_fact('is','Started')
  }

  scope :for_printing, ->() {
    where.not(barcode: nil)
  }

  scope :assets_for_queries, ->(queries) {
    queries.each_with_index.reduce(Asset) do |memo, list|
      query = list[0]
      index = list[1]
      if query.predicate=='barcode'
        memo.where(barcode: query.object)
      else
        asset = Asset.where(barcode: query.object).first
        if asset
          memo.joins(
            "INNER JOIN facts AS facts#{index} ON facts#{index}.asset_id=assets.id"
            ).where("facts#{index}.predicate" => query.predicate,
            "facts#{index}.object_asset_id" => asset.id)
        else
          memo.joins(
            "INNER JOIN facts AS facts#{index} ON facts#{index}.asset_id=assets.id"
            ).where("facts#{index}.predicate" => query.predicate,
            "facts#{index}.object" => query.object)
        end
      end
    end
  }


  def update_compatible_activity_type
    ActivityType.not_deprecated.all.each do |at|
      activity_types << at if at.compatible_with?(self)
    end
  end

  def to_n3
    render :n3
  end
end
