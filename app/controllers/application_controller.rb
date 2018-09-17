# frozen_string_literal: true

require_dependency 'well_helpers'
class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  include SessionHelper

  def api_connection_options
    Limber::Application.config.api.v1.connection_options.dup
  end

  protect_from_forgery

  def check_for_current_user!
    return true if current_user_uuid.present?

    redirect_to(
      search_path,
      alert: 'You must be logged in to do that. Performing actions in multiple tabs can log you out.'
    )
  end
end
