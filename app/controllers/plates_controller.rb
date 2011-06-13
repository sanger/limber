require "ostruct"
class PlatesController < ApplicationController
  
  before_filter :get_printers_and_lables, :on => [ :show, :update ]
  
  def search
    redirect_to plate_path(:id => params[:plate_barcode]) unless params[:plate_barcode].blank?

  end

  def show
    @plate = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:id])
    
    respond_to do |format|
      format.html
    end
  end

  def update
    @plate = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:id])

    @plate.update_attributes!(params[:sequencescape_plate])
    
    respond_to do |format|
      format.html { render :show}
    end
  end


  # Private Stuff...
  
  def get_printers_and_lables
    # This needs to be done properly through the barcode printing API...
    @barcode_label = Sequencescape::BarcodeLabel.new({:printer => :BARCODE_PRINTER_NOT_SET})
    @printers      = { "H104_bd" => :h104_bd, "G206_bc" => :g206_bc }
  end
  private :get_printers_and_lables
end
