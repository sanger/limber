
Rails.application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :email_prefix => "[Limber - #{Rails.env.upcase}] ",
    :sender_address => %("Projects Exception Notifier" <#{Rails.application.config.admin_email}>),
    :exception_recipients => %W(#{Rails.application.config.exception_recipients})
  }
