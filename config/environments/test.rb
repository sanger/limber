# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV['CI'].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Unlike controllers, the mailer instance doesn't have any context about the
  # incoming request so you'll need to provide the :host parameter yourself.
  config.action_mailer.default_url_options = { host: 'www.example.com' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.admin_email = 'nnnnnnnnnnnnnnnn'
  config.exception_recipients = 'nnnnnnnnnnnnnnnn'

  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # API v1 config (deprecated)
  config.api = ActiveSupport::OrderedOptions.new
  config.api.v1 = ActiveSupport::OrderedOptions.new
  config.api.v1.connection_options = ActiveSupport::OrderedOptions.new
  config.api.v1.connection_options.namespace = 'Limber'
  config.api.v1.connection_options.url = 'http://example.com:3000/'
  config.api.v1.connection_options.authorisation = 'testing'

  # API v2 config
  config.api.v2 = ActiveSupport::OrderedOptions.new
  config.api.v2.connection_options = ActiveSupport::OrderedOptions.new
  config.api.v2.connection_options.url = 'http://example.com:3000/api/v2'
  config.api.v2.connection_options.js_url = 'http://example.com:3000/api/v2'
  config.api.v2.connection_options.authorisation = 'test'

  # URL for Sequencescape
  config.sequencescape_url = 'http://localhost:3000'

  # Label printing services
  config.pmb_uri = 'http://example.com:3002/v1/'
  config.sprint_uri = 'http://example_sprint.com/graphql'

  # Traction
  config.traction_ui_uri = 'http://localhost:5173/#'
  config.traction_service_uri = 'http://localhost:3100/v1'
end
