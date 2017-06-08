# frozen_string_literal: true
require 'parsers/symphony'

class Upload < ApplicationRecord
  belongs_to :step
  belongs_to :activity

  before_save :apply_parsers

  def has_step?
    !step.nil?
  end

  def apply_parsers
    activity.asset_group.assets.each do |asset|
      Parsers::Symphony.new(data).add_assets(asset) if Parsers::Symphony.valid_for?(data)
    end
  end
end
