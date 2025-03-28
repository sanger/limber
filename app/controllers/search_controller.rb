# frozen_string_literal: true

# Handles most of the indexes of plates/tubes
class SearchController < ApplicationController
  class InputError < StandardError
  end

  def new
  end

  def ongoing_plates # rubocop:todo Metrics/AbcSize
    plate_search = api.search.find(Settings.searches.fetch('Find plates'))
    @purpose_options = helpers.purpose_options('plate')
    @search_options = OngoingPlate.new(ongoing_plate_search_params)

    @search_options.page = params['page'].to_i if params['page'].present?
    @search_results = plate_search.all(Limber::Plate, @search_options.search_parameters)
    @search_options.total_results = @search_results.size
  end

  def ongoing_tubes # rubocop:todo Metrics/AbcSize
    tube_search = api.search.find(Settings.searches.fetch('Find tubes'))
    @purpose_options = helpers.purpose_options('tube')
    @search_options = OngoingTube.new(ongoing_tube_search_params)
    @search_options.page = params['page'].to_i if params['page'].present?

    @search_results = tube_search.all(Limber::Tube, @search_options.search_parameters)
    @search_options.total_results = @search_results.size
  end

  def qcables
    respond_to { |format| format.json { redirect_to find_qcable(qcable_barcode) } }
  rescue Sequencescape::Api::ResourceNotFound, ActionController::ParameterMissing, InputError => e
    render json: { 'error' => e.message }
  end

  def create
    raise 'You have not supplied a labware barcode' if params[:plate_barcode].blank?

    result = find_labware(params[:plate_barcode])

    respond_to do |format|
      format.html { redirect_to result }
      format.json { redirect_to result }
    end
  rescue StandardError => e
    handle_create_error(e)
  end

  def find_labware(barcode)
    Sequencescape::Api::V2
      .minimal_labware_by_barcode(barcode)
      .tap { |labware| raise "Sorry, could not find labware with the barcode '#{barcode}'." if labware.nil? }
  end

  def find_qcable(barcode)
    api.search.find(Settings.searches['Find qcable by barcode']).first(barcode:)
  rescue Sequencescape::Api::ResourceNotFound => e
    raise e, "Sorry, could not find qcable with the barcode '#{barcode}'."
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

  def handle_create_error(error)
    flash.now[:error] = error.message

    respond_to do |format|
      format.html { render :new, status: :not_found }
      format.json { render json: { error: error.message }, status: :not_found }
    end
  end
end
