# Module that provides functionality to generate a default uuid
module Uuidable
  extend ActiveSupport::Concern
  included { attribute :uuid, default: -> { SecureRandom.uuid } }
end
