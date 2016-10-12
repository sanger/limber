Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  # Disabled as we don't have ActiveRecord AR_CHANGE
  # config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Legacy options. Look at loading with eg. config_for
  # Email settings...
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = false

  config.action_mailer.delivery_method = :test
  config.action_mailer.smtp_settings = { }

  config.admin_email          = "nnnnnnnnnnnnnnnn"
  config.exception_recipients = "nnnnnnnnnnnnnnnn"

  config.api_connection_options               = ActiveSupport::OrderedOptions.new
  config.api_connection_options.namespace     = 'Limber'
  config.api_connection_options.url           = ENV.fetch('API_URL','http://localhost:3000/api/1/')
  config.api_connection_options.authorisation = 'development'


  config.qc_submission_name = "MiSeq for QC"
  # By default used first study/project
  config.study_uuid = nil
  config.project_uuid = nil
  config.request_options = {
    "read_length" => 11,
    "fragment_size_required" => {
      "from" => 100,
      "to"   => 100
    }
  }
end
