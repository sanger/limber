# frozen_string_literal: true

require 'csv'

class LabwareController < ApplicationController
  before_action :locate_labware, only: :show
  before_action :get_printers, only: [:show]
  before_action :check_for_current_user!, only: [:update]

  def locate_labware
    @labware ||= locate_labware_identified_by(params[:id])
  end
  private :locate_labware

  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers

  def state_changer_for(purpose_uuid, labware_uuid)
    StateChangers.lookup_for(purpose_uuid).new(api, labware_uuid, current_user_uuid)
  end
  private :state_changer_for

  def show
    @presenter = presenter_for(@labware)
    @presenter.suitable_labware do
      respond_to do |format|
        format.html do
          render @presenter.page
          response.headers['Vary'] = 'Accept'
        end
        format.csv do
          render @presenter.csv
          response.headers['Content-Disposition'] = "attachment; filename=#{@presenter.filename(params['offset'])}" if @presenter.filename
          response.headers['Vary'] = 'Accept'
        end
        format.json do
          response.headers['Vary'] = 'Accept'
        end
      end
      return
    end
    redirect_to(
      search_path,
      notice: @presenter.errors
    )
    return
  rescue Presenters::UnknownPlateType => exception
    redirect_to(
      search_path,
      notice: "#{exception.message}. Perhaps you are using the wrong pipeline application?"
    )
  end

  def update
    state_changer_for(params[:purpose_uuid], params[:id]).move_to!(params[:state], params[:reason], params[:customer_accepts_responsibility])

    respond_to do |format|
      format.html do
        redirect_to(
          search_path,
          notice: "Labware: #{params[:labware_ean13_barcode]} has been changed to a state of #{params[:state].titleize}.#{params[:customer_accepts_responsibility] ? ' The customer will still be charged.' : ''}"
        )
      end
    end
  rescue StateChangers::StateChangeError => exception
    respond_to do |format|
      format.html { redirect_to(search_path, alert: exception.message) }
      format.csv
    end
  end
end
