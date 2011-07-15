class SearchController < ApplicationController
  before_filter :collect_all_ongoing_plates,  :only => :new

  def new
    session[:user_uuid] = nil
  end
  
  def create
    raise "You have not supplied a plate barcode" if params[:plate_barcode].blank?

    find_user
    
    respond_to do |format|
      format.html { redirect_to api.search.find(Settings.searches['Find asset by barcode']).first(:barcode => params[:plate_barcode]) }
    end


  rescue Sequencescape::Api::ResourceNotFound => exception
    @ongoing       = []
    flash[:notice] = 'Could not find the plate with the specified barcode'

    respond_to do |format|
      format.html { render :new }
    end
  rescue => exception
    @ongoing       = []
    flash[:notice] = exception.message

    respond_to do |format|
      format.html { render :new }
    end
  end

  def collect_all_ongoing_plates
    @ongoing = api.search.find(Settings.searches['Find pulldown plates']).all(Pulldown::Plate, :state => [ 'pending', 'started' ])
  end
  private :collect_all_ongoing_plates

  def find_user
    session[:user_uuid] = nil
    return if params[:user_id].blank?
    session[:user_uuid] = find_user_by_swipecard(params[:user_id])
  end

end
