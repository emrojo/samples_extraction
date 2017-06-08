# frozen_string_literal: true
json.array!(@activities) do |activity|
  json.extract! activity, :id
  json.url activity_url(activity, format: :json)
end
