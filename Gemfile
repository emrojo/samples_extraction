source 'https://rubygems.org'

# Service libraries
gem 'bootsnap', require: false
gem 'daemons'
gem 'delayed_job_active_record'
gem 'hiredis'
gem 'mysql2'
gem 'puma'
gem 'redis', '< 5'
gem 'sanger_warren' # Wraps bunny and manages connection pools and configuration

# Rails and framework libraries
gem 'aasm'
gem 'activerecord-import'
gem 'activerecord-session_store'
gem 'micro_token'
gem 'rails', '~> 6.1'
gem 'tzinfo-data'

# Rails views and UI
gem 'bootstrap_form'
gem 'bootstrap-sass'
gem 'jquery-rails'
gem 'js_cookie_rails'
gem 'react-rails'
gem 'sass-rails'
gem 'sprockets-rails'
gem 'turbolinks'
gem 'webpacker'
gem 'webpacker-react'
gem 'will_paginate'
gem 'will_paginate-bootstrap'

# Javascript UI
gem 'ace-rails-ap'
gem 'dropzonejs-rails'
gem 'ejs'
gem 'rails-assets-tether'

# Serializers
gem 'jbuilder'
gem 'oj'
gem 'rdf-n3'

# Traction endpoints
gem 'json_api_client'
gem 'jsonapi-resources'

# Tools
gem 'pmb-client', git: 'https://github.com/sanger/pmb-client.git'
gem 'sanger_barcode_format', git: 'https://github.com/sanger/sanger_barcode_format.git'

# Sequencescspae
gem 'faraday'
gem 'rest-client'
gem 'sequencescape-client-api', require: 'sequencescape'

# Debugging
gem 'rb-readline'

# Docs
gem 'yard'

# Feature flags
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'

group :development, :test do
  # Call 'pry' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'ruby-growl'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'json-schema'
  gem 'launchy'
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console' # , '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails'

  # Mocks APi connections, and also prevents inadvertent network connections being made.
  gem 'webmock'
end

group :deployment do
  gem 'exception_notification'
  gem 'gmetric', '~>0.1.3'
end
