class LabwareController < ApplicationController
  before_filter :locate_labware, :only => [ :show, :update ]
  before_filter :get_printers, :only   => [ :show, :update ]
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
    begin
      @presenter = presenter_for(@labware)
      respond_to do |format|
        format.html {
          render @presenter.page
          response.headers["Vary"]="Accept"
        }
        format.csv {
          render @presenter.csv
          response.headers['Content-Disposition']="inline; filename=#{@presenter.filename(params['offset'])}" if @presenter.filename
          response.headers["Vary"]="Accept"
        }
        format.json {
          response.headers["Vary"]="Accept"
        }
      end
    rescue Presenters::PlatePresenter::UnknownPlateType => exception
      redirect_to(
        search_path,
        :notice => "#{exception.message}. Perhaps you are using the wrong pipeline application?"
      )
    end
  end

  def update
    begin
      state_changer_for(params[:purpose_uuid], params[:id]).move_to!(params[:state], params[:reason],params[:customer_accepts_responsibility])

      respond_to do |format|
        format.html {
          redirect_to(
            search_path,
            :notice => "Labware: #{params[:labware_ean13_barcode]} has been changed to a state of #{params[:state].titleize}.#{params[:customer_accepts_responsibility] ? ' The customer will still be charged.':''}"
          )
        }
      end

    rescue StateChangers::StateChangeError => exception
      respond_to do |format|
        format.html { redirect_to(search_path, :alert=> exception.message) }
        format.csv
      end
    end
  end

end
