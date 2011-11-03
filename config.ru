# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

config = PulldownPipeline::Application.config

# Add exception notification...
config.middleware.use ExceptionNotifier,
  :email_prefix         => "[Pulldown Pipeline - #{Rails.env.upcase}] ",
  :sender_address       => %("Projects Exception Notifier" <#{config.admin_email}>),
  :exception_recipients => %W(#{config.exception_recipients})

run PulldownPipeline::Application

