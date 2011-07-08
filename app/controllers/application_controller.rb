class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  delegate :api_connection_options, :to => 'PulldownPipeline::Application.config'

  protect_from_forgery
  
  def current_user_uuid
    session[:user_uuid]
  end

  helper_method :current_user_uuid
end
