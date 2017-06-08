# frozen_string_literal: true
json.array!(@step_types) do |step_type|
  json.extract! step_type, :id
  json.url step_type_url(step_type, format: :json)
end
