require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SamplesExtraction
  class Application < Rails::Application # rubocop:todo Style/Documentation
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_job.queue_adapter = :delayed_job

    config.team_name = 'LIMS and Informatics'
    config.team_url = 'http://www.sanger.ac.uk/science/groups/production-software-development'
    config.admin_email = 'admin@test.com'

    config.barcode_prefix = 'SE'

    # Load the warren configuration from config/warren.yml
    # Warren controls connection to the RabbitMQ server
    config.warren = config_for(:warren)
  end
end
