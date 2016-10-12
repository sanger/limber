require File.expand_path('../boot', __FILE__)

# Usually we load everything with
# require 'rails/all'
# But we don't want ActiveRecord, so instead we load everything independently
# The full list (rails 4.2) is provided below. Unwanted components are commented out
# to make them easy to switch on and off.
# source: http://guides.rubyonrails.org/v4.2/initialization.html#railties-lib-rails-all-rb
# This list will need to be updated with future versions of rails.
# If active_record gets added, search for AR_CHANGE to find the options that need to be
# re-enabled
[
  # 'active_record',
  'action_controller',
  'action_view',
  'action_mailer', # Used for exception notifier
  'rails/test_unit',
  'sprockets'
].each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Limber
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # Disabled as we don't have ActiveRecord! AR_CHANGE
    # config.active_record.raise_in_transactional_callbacks = true
  end
end
