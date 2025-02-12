# frozen_string_literal: true

require_relative "boot"

require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Limber
  class Application < Rails::Application
    # Initialize configuration defaults for Rails version.
    config.load_defaults 7.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Printer templates
    config.label_templates = config_for(:label_templates)

    # Logging
    config.logger = Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new

    # Bioscan mBrave tag layout templates
    config.mbrave = config_for(:mbrave)
  end
end
