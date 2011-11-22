ActionMailer::Base.delivery_method = :sendmail

config = PulldownPipeline::Application.config

config.after_initialize do
  # Add exception notification...
  config.middleware.use ExceptionNotifier,
    :email_prefix         => "[Pulldown Pipeline - #{Rails.env.upcase}] ",
    :sender_address       => %("Projects Exception Notifier" <#{config.admin_email}>),
    :exception_recipients => %W(#{config.exception_recipients})
end
