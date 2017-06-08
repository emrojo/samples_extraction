# frozen_string_literal: true
if ENV['RAILS_ENV'] == 'debug'
  Rails.configuration.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.growl = false
    # Bullet.xmpp = { :account  => 'bullets_account@jabber.org',
    #                 :password => 'bullets_password_for_jabber',
    #                 :receiver => 'your_account@jabber.org',
    #                 :show_online_status => true }
    Bullet.rails_logger = true
    Bullet.honeybadger = false
    Bullet.bugsnag = false
    Bullet.airbrake = false
    Bullet.rollbar = false
    Bullet.add_footer = true
    Bullet.stacktrace_includes = %w(your_gem your_middleware)
    Bullet.stacktrace_excludes = %w(their_gem their_middleware)
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
  end
end
