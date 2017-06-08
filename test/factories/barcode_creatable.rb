# frozen_string_literal: true
require 'barcode'

FactoryGirl.define do
  sequence :barcode do |n|
    n
  end

  sequence :barcode_creatable do |n|
    "#{Barcode.CREATABLE_PREFIX}#{n}"
  end
end
