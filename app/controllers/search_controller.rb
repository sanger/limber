class SearchController < ApplicationController
  before_filter :collect_all_ongoing_plates,  :only => :new

  def new
    session[:user_uuid] = nil
  end
  
  # TODO Move search to a separate controller
  # whilst you're at it add a search object with error handling too... :)
  def create
    raise "You have not supplied a plate barcode" if params[:plate_barcode].blank?

    find_user
    
    respond_to do |format|
      format.html { redirect_to api.search.find(Settings.searches['Find asset by barcode']).first(:barcode => params[:plate_barcode]) }
    end
  rescue Sequencescape::Api::ResourceNotFound => exception
    respond_to do |format|
      format.html { redirect_to(search_path, :notice => 'Could not find the plate with the specified barcode') }
    end
  rescue => exception
    respond_to do |format|
      format.html { redirect_to(search_path, :notice => exception.message) }
    end
  end

  def collect_all_ongoing_plates
    @ongoing = api.search.find(Settings.searches['Find pulldown plates']).all(Pulldown::Plate, :state => [ 'pending', 'started' ])
  end
  private :collect_all_ongoing_plates

  def find_user
    session[:user_uuid] = nil
    return if params[:user_id].blank?
    session[:user_uuid] = api.search.find(Settings.searches["Find user by swipecard code"]).first(:swipecard_code => params[:user_id]).uuid
  end
end
