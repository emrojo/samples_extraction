# frozen_string_literal: true
json.extract! @user, :username, :fullname, :barcode, :role, :tube_printer_name, :plate_printer_name
json.url user_url(@user, format: :json)
