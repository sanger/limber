require "ostruct"
class PlatesController < ApplicationController
  before_filter :assign_api
  attr_accessor :api
  
  def search
    redirect_to plate_path(:id => params[:plate_barcode]) unless params[:plate_barcode].blank?
    
  end

  def show
    @plate         = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:id])
    @printers      = { "A Printer" => :a_printer}
    
    # This needs to be done properly through the barcode printing API...
    @barcode_label = Sequencescape::BarcodeLabel.new({:printer => :BARCODE_PRINTER_NOT_SET})
    
    respond_to do |format|
      format.html
    end
  end
  
  def update
    @plate         = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:id])
    @printers      = { "A Printer" => :a_printer}
    
    # This needs to be done properly through the barcode printing API...
    @barcode_label = Sequencescape::BarcodeLabel.new({:printer => :BARCODE_PRINTER_NOT_SET})
    
    respond_to do |format|
      format.html { render :show}
    end
  end
  
  
  # Private Stuff...
  def assign_api
   self.api ||= ::Sequencescape::Api.new
  end
  private :assign_api
end
