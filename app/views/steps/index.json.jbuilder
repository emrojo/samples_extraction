# frozen_string_literal: true
json.array!(@steps) do |step|
  json.extract! step, :id
  json.url step_url(step, format: :json)
end
