# frozen_string_literal: true
class Capacity < ActiveRecord::Base
  belongs_to :instrument
  belongs_to :activity_type
end
