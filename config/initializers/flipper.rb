# frozen_string_literal: true

# Flipper https://www.flippercloud.io controls our feature flags
# We use the redis adapter. https://www.flippercloud.io/docs/adapters/redis
# This initializer configures the adapter to use the Rails.configuration.redis_url
# variable, rather than REDIS_URL or FLIPPER_REDIS_URL instead. This maps with
# what we are already using.
require 'flipper/adapters/redis'
require 'yaml'

FLIPPER_FEATURES = YAML.load_file('./config/feature_flags.yml')

Flipper.configure do |config|
  if Rails.configuration.redis_url.present?
    config.adapter { Flipper::Adapters::Redis.new(Redis.new(url: Rails.configuration.redis_url)) }
  else
    config.adapter { Flipper::Adapters::Memory.new }
  end
end

Flipper::UI.configure do |config|
  config.descriptions_source = ->(_keys) { FLIPPER_FEATURES }
  config.banner_text = "#{Rails.application.engine_name} [#{Rails.env}]"
  config.banner_class = Rails.env.production? ? 'danger' : 'info'

  # If there aren't any flags in the list, flipper will render the Taylor Swift
  # video 'Blank Space'. Unfortunately the permissions on my browser at least
  # meant that this didn't work, and it wasn't entirely clear that it wasn't
  # hiding anything important. So sadly, I have to disable the feature.
  # But as I have nothing against TayTay:
  # https://www.youtube.com/watch?v=e-ORhEE9VVg
  config.fun = false

  # Defaults to false. Set to true to show feature descriptions on the list
  # page as well as the view page.
  config.show_feature_description_in_list = true
end

begin
  # Automatically add tracking of features in the yaml file
  FLIPPER_FEATURES.each_key { |feature| Flipper.add(feature) }
rescue Redis::CannotConnectError => e
  Rails.logger.warn(e.message)
  Rails.logger.warn('Features not registered with flipper')
end
