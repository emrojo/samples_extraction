Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  config.action_cable.allowed_request_origins = [%r{https?://\S+}]

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :notify

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  config.allow_concurrency = true
  config.redis_enabled = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new
  config.log_level = :info
  config.log_tags = [:request_id]
  config.time_zone = 'London'
  config.eager_load = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.pmb_uri = ENV.fetch('SE_PMB_URI', 'http://localhost:10000/v1')
  config.redis_url = ENV.fetch('SE_REDIS_URI', 'redis://127.0.0.1:6379')
  config.ss_uri = ENV.fetch('SE_SS_URI', 'http://localhost:3000/api/1/')
  config.ss_api_v2_uri = ENV.fetch('SE_SS_API_V2_URI', 'http://localhost:3000')

  config.ss_authorisation = ENV.fetch('SS_AUTHORISATION_TOKEN', '')
  config.searcher_name_by_barcode = 'Find assets by barcode'

  config.searcher_name_by_barcode = 'Find assets by barcode'
  config.printing_enabled = ENV.fetch('PRINTING_ENABLED', '') == 'true'
  config.printing_disabled = !config.printing_enabled
  config.redis_enabled = true

  config.inference_engine = :default
  config.cwm_path = ENV.fetch('CWM_PATH', '')
  config.default_n3_resources_url = ENV.fetch('N3_RESOURCES_URL', '')

  config.enable_reasoning = true
end
