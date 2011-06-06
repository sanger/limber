class CreationController < ApplicationController

  def new
    # TODO Should be by UUID but it's not in the stubs yet...
    # TODO move into the form object's constructor
    @parent_plate   = api.search.find(Settings.asset_from_barcode).first(:barcode => params[:plate_id])
    @plate_purpose  = api.plate_purpose.find(params[:plate_purpose_uuid])
    
    # This might need to use an internal uuid to class name lookup
    @creation_form  = Forms.const_get(params[:plate_purpose_uuid]).new
    
    respond_to do |format|
      format.html { render @creation_form.class.const_get(:PARTIAL) }
    end
  end
  
  def create
    @creation_form = Forms.const_get(params[:plate][:plate_purpose_uuid]).new(params[:plate].merge(:api => api))
    
    if @creation_form.save
      respond_to do |format|
        format.html { redirect_to plate_path(@creation_form.child.barcode) }
      end
    else
      raise "Not saving...."
    end
  end
end
