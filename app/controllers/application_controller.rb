class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  delegate :api_connection_options, :to => 'PulldownPipeline::Application.config'

  protect_from_forgery
  
  def current_user_uuid
    session[:user_uuid]
  end

  helper_method :current_user_uuid

  def set_user_by_swipecard!(card_id)
    session[:user_uuid] = find_user_by_swipecard(card_id)
  end

  def find_user_by_swipecard(card_id)
    api.search.find(Settings.searches["Find user by swipecard code"]).first(:swipecard_code => card_id).uuid
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, that swipecard could not be found. Please try again or contact your administator.'
  end
end
