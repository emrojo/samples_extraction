Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  # config.eager_load = false
  config.allow_concurrency = false
  config.eager_load = true

  # Configure static file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.middleware.use RackSessionAccess::Middleware

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.pmb_uri = ENV.fetch('SE_PMB_URI', 'http://localhost:10000/v1')
  config.redis_url = ENV.fetch('SE_REDIS_URI', 'redis://127.0.0.1:6379')
  config.ss_uri =  ENV.fetch('SE_SS_URI', 'http://localhost:3000/api/1/')
  config.ss_api_v2_uri = ENV.fetch('SE_SS_API_V2_URI', 'http://localhost:3000')

  config.searcher_name_by_barcode = 'Find assets by barcode'
  config.ss_authorisation =  'test'
  config.printing_disabled = true
  config.default_n3_resources_url = nil
  config.redis_enabled = false

  config.inference_engine = :default
  config.cwm_path = ENV.fetch('CWM_PATH', '')

  config.enable_reasoning = true

  config.active_record.verbose_query_logs = true
end
