class SearchController < ApplicationController
  
  # TODO Move search to a separate controller
  # whilst you're at it add a search object with error handling too... :)
  def new
    if params[:plate_barcode].blank?
      render :new
    else
      @plate = api.search.find(Settings.searches['Find asset by barcode']).first(:barcode => params[:plate_barcode])
      redirect_to plate_path(:id => @plate.uuid)
      # render :show, :id => @plate.uuid
    end
  end
  
end
