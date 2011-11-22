PulldownPipeline::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.api_connection_options               = ActiveSupport::OrderedOptions.new
  config.api_connection_options.namespace     = 'Pulldown'
  config.api_connection_options.url           = 'http://localhost:3000/api/1/'
  # config.api_connection_options.authorisation = '372d4ece3d05deda9b5588dd9d2b23a0'
  config.api_connection_options.authorisation = 'development'


  # Email settings...
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => "mail.sanger.ac.uk",
    :port    => 25,
    :domain  => "EVO18720.internal.sanger.ac.uk"
  }

  config.admin_email          = "sd9@sanger.ac.uk"
  config.exception_recipients = "sd9@sanger.ac.uk"

end

