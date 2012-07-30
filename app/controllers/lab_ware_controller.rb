class LabWareController < ApplicationController
  before_filter :locate_lab_ware, :only => [ :show ]
  before_filter :get_printers, :only => [ :show ]

  def locate_lab_ware
     @lab_ware = locate_lab_ware_identified_by(params[:id])
  end
  private :locate_lab_ware

  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers

  def state_changer_for(plate_purpose_uuid, labware_uuid)
    StateChangers.lookup_for(plate_purpose_uuid).new(api, labware_uuid, current_user_uuid)
  end

  def show
    @presenter = presenter_for(@lab_ware)
    respond_to do |format|
      format.html { render @presenter.page }
      format.csv
    end
  end

  def update
    state_changer_for(params[:plate_purpose_uuid], params[:id]).move_to!(params[:state], params[:reason])

    respond_to do |format|
      format.html { 
        redirect_to(
          search_path,
          :notice => "State for plate #{params[:plate_ean13_barcode]} has been changed to #{params[:state]}"
        )
      }
    end
  end
end
