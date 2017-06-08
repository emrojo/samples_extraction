# frozen_string_literal: true
json.array!(@instruments) do |instrument|
  json.extract! instrument, :id, :barcode
  json.url instrument_url(instrument, format: :json)
end
