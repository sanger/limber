# frozen_string_literal: true

require 'csv'

# Inherited by PlatesController and TubesController
# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
class LabwareController < ApplicationController
  UUID = /\A[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}\z/.freeze

  before_action :locate_labware, only: [:show, :print_pools]
  before_action :find_printers, only: [:show]
  before_action :check_for_current_user!, only: [:update]

  rescue_from Presenters::UnknownLabwareType, with: :unknown_type

  def show
    @presenter = presenter_for(@labware)
    logger.debug("presenter: #{@presenter.class}")
    logger.debug("pools: #{@presenter.pools.length}")

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

  def print_pools
    @presenter = presenter_for(@labware)

    response.headers['Vary'] = 'Accept'
    respond_to do |format|
      format.html do
        logger.debug(@presenter.pools)
        logger.debug(@presenter.pools.length)
        @presenter.pools.each do |pool|
          logger.debug(pool.subpools.length)
          logger.debug(pool.subpools.first.well_requests.first.request.inspect)
          logger.debug(pool.subpools.first.well_requests.first.request.pre_capture_plex_level)
          logger.debug(pool.subpools.first.well_requests.first.request.submission)
        end
        @presenter.wells_by_row.each do |row_label, row_wells|
          logger.debug(row_label)
          row_wells.each do |well|
            logger.debug(well.inspect)
            # logger.debug(well.methods - Object.methods)
            logger.debug(@presenter.pool_or_subpool_index(well))
            # break
          end
          # break
        end
        render @presenter.print_pools_page
        # render inline: "test"
      end
      format.csv {}
      format.json {}
    end
  end

  def update
    state_changer.move_to!(params[:state], params[:reason], params[:customer_accepts_responsibility])

    notice = +"Labware: #{params[:labware_barcode]} has been changed to a state of #{params[:state].titleize}."
    notice << ' The customer will still be charged.' if params[:customer_accepts_responsibility]

    respond_to do |format|
      format.html do
        redirect_to(
          search_path,
          notice: notice
        )
      end
    end
  rescue StateChangers::StateChangeError => e
    respond_to do |format|
      format.html { redirect_to(search_path, alert: e.message) }
      format.csv
    end
  end

  private

  def search_param
    { uuid: params[:id] }
    # THis will allow us to switch to human barcodes in the url
    # But currently causes a tonne of test failures, partly due to invalid uuids.
    # case params[:id]
    # when UUID then { uuid: params[:id] }
    # else { barcode: params[:id] }
    # end
  end

  def unknown_type
    redirect_to(
      search_path,
      alert: 'Unknown labware. Perhaps you are using the wrong pipeline application?'
    )
  end

  def state_changer
    state_changer_for(params[:purpose_uuid], params[:id])
  end

  def locate_labware
    @labware ||= locate_labware_identified_by_id
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
