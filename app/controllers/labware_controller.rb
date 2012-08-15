class LabwareController < ApplicationController
  before_filter :locate_labware, :only => [ :show ]
  before_filter :get_printers, :only   => [ :show ]
  before_filter :check_for_current_user!, :only => [ :update ]

  def locate_labware
     @labware = locate_labware_identified_by(params[:id])
  end
  private :locate_labware

  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers

  def check_for_current_user!
    redirect_to(
      search_path,
      :alert => "Please login to change the state of any labware."
    ) unless current_user_uuid.present?
  end
  private :check_for_current_user!

  def state_changer_for(purpose_uuid, labware_uuid)
    StateChangers.lookup_for(purpose_uuid).new(api, labware_uuid, current_user_uuid)
  end
  private :state_changer_for

  def show
    @presenter = presenter_for(@labware)
    respond_to do |format|
      format.html { render @presenter.page }
      format.csv
    end
  end

  def update
    state_changer_for(params[:purpose_uuid], params[:id]).move_to!(params[:state], params[:reason])

    respond_to do |format|
      format.html { 
        redirect_to(
          search_path,
          :notice => "Labware: #{params[:labware_ean13_barcode]} has been changed to a state of #{params[:state].titleize}"
        )
      }
    end
  end

end
