# frozen_string_literal: true

require 'csv'

class LabwareController < ApplicationController
  before_action :locate_labware, only: :show
  before_action :find_printers, only: [:show]
  before_action :check_for_current_user!, only: [:update]

  rescue_from Presenters::UnknownLabwareType, with: :unknown_type

  def show
    @presenter = presenter_for(@labware)

    response.headers['Vary'] = 'Accept'
    respond_to do |format|
      format.html do
        render @presenter.page
      end
      format.csv do
        render @presenter.csv
        response.headers['Content-Disposition'] = "attachment; filename=#{@presenter.filename(params['offset'])}" if @presenter.filename
      end
      format.json {}
    end
  end

  def update
    state_changer.move_to!(params[:state], params[:reason], params[:customer_accepts_responsibility])

    notice = +"Labware: #{params[:labware_ean13_barcode]} has been changed to a state of #{params[:state].titleize}."
    notice << ' The customer will still be charged.' if params[:customer_accepts_responsibility]

    respond_to do |format|
      format.html do
        redirect_to(
          search_path,
          notice: notice
        )
      end
    end
  rescue StateChangers::StateChangeError => exception
    respond_to do |format|
      format.html { redirect_to(search_path, alert: exception.message) }
      format.csv
    end
  end

  private

  def unknown_type
    redirect_to(
      search_path,
      error: 'Unknown labware. Perhaps you are using the wrong pipeline application?'
    )
  end

  def state_changer
    state_changer_for(params[:purpose_uuid], params[:id])
  end

  def locate_labware
    @labware ||= locate_labware_identified_by(params[:id])
  end

  def find_printers
    @printers = api.barcode_printer.all
  end

  def state_changer_for(purpose_uuid, labware_uuid)
    StateChangers.lookup_for(purpose_uuid).new(api, labware_uuid, current_user_uuid)
  end

  def presenter_for(labware)
    Presenters.lookup_for(labware).new(
      api: api,
      labware: labware
    )
  end
end
