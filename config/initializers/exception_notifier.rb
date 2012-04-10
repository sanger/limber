config = PulldownPipeline::Application.config

ActionMailer::Base.delivery_method = config.action_mailer.delivery_method || :sendmail

# Add exception notification...
config.middleware.use(ExceptionNotifier,{
  :email_prefix         => "[Pulldown Pipeline - #{Rails.env.upcase}] ",
  :sender_address       => %("Projects Exception Notifier" <#{config.admin_email}>),
  :exception_recipients => %W(#{config.exception_recipients})
  })
