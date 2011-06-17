class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  delegate :api_connection_options, :to => 'PulldownPipeline::Application.config'
  
  
  protect_from_forgery
  
end
