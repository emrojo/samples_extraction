# frozen_string_literal: true
json.id @asset_group.id
json.assets @asset_group.assets do |asset|
  json.barcode asset.barcode
  json.facts asset.facts do |fact|
    json.extract! fact, :predicate, :object
  end
end
