# frozen_string_literal: true

require_dependency 'well_helpers'

# Base controller for application
# Sets up:
# - session validation on #check_for_current_user!
class ApplicationController < ActionController::Base
  include SessionHelper
  include FlashTruncation

  protect_from_forgery

  def check_for_current_user!
    return true if current_user_uuid.present?

    redirect_to(
      search_path,
      alert: 'You must be logged in to do that. Performing actions in multiple tabs can log you out.' # rubocop:todo Rails/I18nLocaleTexts
    )
  end
end
