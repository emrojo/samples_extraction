# frozen_string_literal: true
json.extract! printer, :id, :created_at, :updated_at
json.url printer_url(printer, format: :json)
