# frozen_string_literal: true
if ENV['RAILS_ENV'] == 'debug'
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
