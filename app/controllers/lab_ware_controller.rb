class LabWareController < ApplicationController
  before_filter :locate_lab_ware, :on => [ :show, :update ]
  def locate_lab_ware
    @lab_ware = locate_lab_ware_identified_by(params[:id])
  end
  private :locate_lab_ware

  before_filter :get_printers, :on => [ :show, :update ]
  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers

  def state_changer_for(labware)
    StateChangers.lookup_for(labware).new(api, labware, current_user_uuid)
  end

  def show
    @presenter = presenter_for(@lab_ware)
    respond_to do |format|
      format.html { render @presenter.page }
      format.csv
    end
  end

  def update
    state_changer_for(@lab_ware).move_to!(params[:state], params[:reason])

    respond_to do |format|
      format.html { redirect_to(search_path, :notice => "State has been changed to #{params[:state]}") }
    end
  end
end
