# frozen_string_literal: true

# Handles most of the indexes of plates/tubes
class SearchController < ApplicationController
  class InputError < StandardError
  end

  def new
  end

  def ongoing_plates
    @purpose_options = helpers.purpose_options('plate')
    @search_options = OngoingPlate.new(ongoing_plate_search_params.merge(page: params['page']&.to_i).compact)
    @search_results =
      Sequencescape::Api::V2::Plate.find_all(@search_options.search_parameters, paginate: @search_options.pagination)
    pagination_metadata(@search_results)
  end

  def ongoing_tubes
    @purpose_options = helpers.purpose_options('tube')
    @search_options = OngoingTube.new(ongoing_tube_search_params.merge(page: params['page']&.to_i).compact)
    @search_results =
      Sequencescape::Api::V2::Tube.find_all(@search_options.search_parameters, paginate: @search_options.pagination)
    pagination_metadata(@search_results)
  end

  def qcables
    respond_to { |format| format.json { redirect_to find_qcable(qcable_barcode) } }
  rescue Sequencescape::Api::ResourceNotFound, ActionController::ParameterMissing, InputError => e
    render json: { 'error' => e.message }
  end

  def create # rubocop:todo Metrics/AbcSize
    raise 'You have not supplied a labware barcode' if params[:plate_barcode].blank?

    respond_to { |format| format.html { redirect_to find_labware(params[:plate_barcode]) } }
  rescue StandardError => e
    flash.now[:error] = e.message

    # rendering new without re-searching for the ongoing plates...
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end

  def find_labware(barcode)
    Sequencescape::Api::V2
      .minimal_labware_by_barcode(barcode)
      .tap { |labware| raise "Sorry, could not find labware with the barcode '#{barcode}'." if labware.nil? }
  end

  def find_qcable(barcode)
    includes = [:labware, { lot: [{ lot_type: :target_purpose }, :template] }].freeze
    Sequencescape::Api::V2::Qcable
      .includes(*includes)
      .where(barcode:)
      .first
      .tap { |qcable| raise "Sorry, could not find qcable with the barcode '#{barcode}'." if qcable.nil? }
  end

  private

  def qcable_barcode
    params.require(:qcable_barcode).strip
  end

  def ongoing_plate_search_params
    params.fetch(:ongoing_plate, {}).permit(:show_my_plates_only, :include_used, purposes: [])
  end

  def ongoing_tube_search_params
    params.fetch(:ongoing_tube, {}).permit(:include_used, purposes: [])
  end

  def pagination_metadata(search_results)
    # Other possible pagination metadata from <JsonApiClient::ResultSet> includes:
    # current_page, total_entries, total_results
    # See the attributes returned by Sequencescape::Api::V2::Plate.find({state:'pending'})
    @search_options.total_pages = search_results.total_pages
  end
end
