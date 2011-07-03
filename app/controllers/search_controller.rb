class SearchController < ApplicationController
  before_filter :collect_all_ongoing_plates,  :only => :new

  def new

  end
  
  # TODO Move search to a separate controller
  # whilst you're at it add a search object with error handling too... :)
  def create
    raise "You have not supplied a plate barcode" if params[:plate_barcode].blank?

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
end
