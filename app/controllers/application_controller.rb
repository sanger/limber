# frozen_string_literal: true

require_dependency 'well_helpers'

# Base controller for application
# Sets up:
# - v1 api support
# - Sequencescape::Api::Rails::ApplicationController imports settings from #api_connection_options
# - session validation on #check_for_current_user!
class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  include SessionHelper
  include FlashTruncation

  def api_connection_options
    Limber::Application.config.api.v1.connection_options.dup
  end

  protect_from_forgery

  def check_for_current_user!
    return true if current_user_uuid.present?

    redirect_to(
      search_path,
      alert: 'You must be logged in to do that. Performing actions in multiple tabs can log you out.' # rubocop:todo Rails/I18nLocaleTexts
    )
  end
end
