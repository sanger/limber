class SearchController < ApplicationController
  
  # TODO Move search to a separate controller
  # whilst you're at it add a search object with error handling too... :)
  def new
    redirect_to plate_path(:id => params[:plate_barcode]) unless params[:plate_barcode].blank?
    if params[:plate_barcode].blank?
      render :search
    else
      @plate = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:plate_barcode])
      redirect_to plate_path(:id => @plate.uuid)
      # render :show, :id => @plate.uuid
    end
  end
  
end
