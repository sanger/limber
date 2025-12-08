# frozen_string_literal: true

# Utility methods to assist with session management
module SessionHelper
  # Toggle class if user is logged in.
  # This is applied to the body, so you shouldn't
  # need to add it to other elements
  def logged_in_class
    current_user_uuid.present? ? 'logged_in' : 'logged_out'
  end

  def logged_in?
    session[:user_uuid].present?
  end

  # Returns the name of the logged in user.
  # Returns guest if no one is logged in.
  def user_name
    session[:user_name] || 'guest'
  end

  def current_user_uuid
    session[:user_uuid]
  end

  def check_for_login!
    return true if session[:user_uuid]

    redirect_back_or_to :search, alert: Ii18n.t('errors.messages.must_be_swiped_in')
  end

  def session_switcher
    link_to 'Log Out', logout_sessions_path, class: 'btn-logout' if logged_in?
  end
end
