class SearchController < ApplicationController
  
  # TODO Move search to a separate controller
  # whilst you're at it add a search object with error handling too... :)
  def new
    redirect_to plate_path(:id => params[:plate_barcode]) unless params[:plate_barcode].blank?
  end

  
end
