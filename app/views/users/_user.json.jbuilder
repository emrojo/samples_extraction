# frozen_string_literal: true
json.extract! user, :id, :barcode, :username, :fullname, :tubeprinter, :plateprinter, :created_at, :updated_at
json.url user_url(user, format: :json)
