# frozen_string_literal: true

require 'csv'

# Inherited by PlatesController and TubesController
# show => Looks up the presenter for the giver purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
class LabwareController < ApplicationController
  UUID = /\A[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}\z/

  before_action :locate_labware, only: :show
  before_action :find_printers, only: [:show]
  before_action :check_for_current_user!, only: [:update]

  rescue_from Presenters::UnknownLabwareType, with: :unknown_type

  layout 'labware'

  def show # rubocop:todo Metrics/AbcSize
    @pipeline_info = Presenters::PipelineInfoPresenter.new(@labware)
    @request_info = Presenters::RequestInfoPresenter.new(@labware)
    @presenter = presenter_for(@labware)

    response.headers['Vary'] = 'Accept'
    respond_to do |format|
      format.html { render @presenter.page }
      format.csv do
        render @presenter.csv
        if @presenter.filename
          response.headers[
            'Content-Disposition'
          ] = "attachment; filename=#{@presenter.filename(params['offset'])}"
        end
      end
      format.json
    end
  end

  def update
    state_changer.move_to!(*update_params)

    notice = "Labware: #{params[:labware_barcode]} has been changed to a state of #{params[:state].titleize}."
    notice << ' The customer will still be charged.' if update_params[2]

    respond_to { |format| format.html { redirect_to(search_path, notice:) } }
  end

  private

  def update_params
    state = params.require(:state)
    state_options = params.require(state)
    [
      state,
      state_options[:reason],
      ActiveModel::Type::Boolean.new.deserialize(state_options[:customer_accepts_responsibility])
    ]
  end

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
      alert: 'Unknown labware. Perhaps you are using the wrong pipeline application?' # rubocop:todo Rails/I18nLocaleTexts
    )
  end

  def state_changer
    state_changer_for(params[:purpose_uuid], params[:id])
  end

  def locate_labware
    @labware = locate_labware_identified_by_id
  end

  def find_printers
    @printers = Sequencescape::Api::V2::BarcodePrinter.all
  end

  def state_changer_for(purpose_uuid, labware_uuid)
    StateChangers.lookup_for(purpose_uuid).new(labware_uuid, current_user_uuid)
  end

  def presenter_for(labware)
    Presenters.lookup_for(labware).new(labware:)
  end
end
