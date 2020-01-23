# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Only load what we need:
# http://guides.rubyonrails.org/initialization.html#railties-lib-rails-all-rb
[
  # 'active_record/railtie',
  'action_controller/railtie',
  'action_view/railtie',
  'action_mailer/railtie',
  'active_job/railtie',
  'action_cable/engine',
  'rails/test_unit/railtie',
  'sprockets/railtie'
].each do |railtie|
  begin
    require railtie.to_s
  rescue LoadError # rubocop:disable Lint/SuppressedException
    # Do nothing. We're mimicking rails/all here, so
    # use the same behaviour.
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
    config.label_templates = config_for(:label_templates)
    config.disable_animations = false

    config.logger = Logger.new(Rails.root.join('log', Rails.env + '.log'), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new
  end
end
