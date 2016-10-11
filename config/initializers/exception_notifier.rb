#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
config = Limber::Application.config

ActionMailer::Base.delivery_method = config.action_mailer.delivery_method || :sendmail

# Add exception notification...
config.middleware.use(ExceptionNotifier,{
  :email_prefix         => "[Limber - #{Rails.env.upcase}] ",
  :sender_address       => %("Projects Exception Notifier" <#{config.admin_email}>),
  :exception_recipients => %W(#{config.exception_recipients})
  })
