class ApplicationController < ActionController::Base
  before_filter :assign_api
  attr_accessor :api
  
  protect_from_forgery
  
  def assign_api
   self.api ||= ::Sequencescape::Api.new
  end
  private :assign_api
  
end
