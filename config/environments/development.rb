# frozen_string_literal: true

# Localhost might need to be rewritten if running inside an environment/container.
# In which case, the value in the LOCALHOST environment variable will be substituted.
def rewrite_localhost(url)
  url.gsub(%r{((?<=http://)|(?<=https://))localhost}i, ENV.fetch('LOCALHOST', 'localhost'))
end

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  # Disabled as no activerecord
  # config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_mailer.delivery_method = :test
  config.action_mailer.smtp_settings = {}

  config.admin_email          = 'nnnnnnnnnnnnnnnn'
  config.exception_recipients = 'nnnnnnnnnnnnnnnn'

  config.api                                     = ActiveSupport::OrderedOptions.new
  config.api.v1                                  = ActiveSupport::OrderedOptions.new
  config.api.v1.connection_options               = ActiveSupport::OrderedOptions.new
  config.api.v1.connection_options.namespace     = 'Limber'
  config.api.v1.connection_options.url           = rewrite_localhost(ENV.fetch('API_URL', 'http://localhost:3000/api/1/'))
  config.api.v1.connection_options.authorisation = ENV.fetch('API_KEY', 'development')

  config.api.v2                                  = ActiveSupport::OrderedOptions.new
  config.api.v2.connection_options               = ActiveSupport::OrderedOptions.new
  config.api.v2.connection_options.url           = rewrite_localhost(ENV.fetch('API2_URL', 'http://localhost:3000/api/v2'))
  config.api.v2.connection_options.js_url        = ENV.fetch('API2_URL', 'http://localhost:3000/api/v2')

  config.qc_submission_name = 'MiSeq for QC'
  # By default used first study/project
  config.study_uuid = nil
  config.project_uuid = nil
  config.request_options = {
    'read_length' => 11
  }
  config.pmb_uri = ENV.fetch('PMB_URI', rewrite_localhost('http://localhost:3002/v1/'))
  config.sprint_uri = 'http://sprint.psd.sanger.ac.uk/graphql'
end
