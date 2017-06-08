# frozen_string_literal: true
json.array!(@kits) do |kit|
  json.extract! kit, :id, :barcode, :max_num_reactions, :num_reactions_performed, :kit_type_id
  json.url kit_url(kit, format: :json)
end
