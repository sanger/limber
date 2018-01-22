# frozen_string_literal: true

class SearchController < ApplicationController
  class InputError < StandardError; end

  before_action :check_for_login!, only: [:my_plates]

  def new; end

  def ongoing_plates
    plate_search = api.search.find(Settings.searches.fetch('Find plates'))
    @purpose_options = helpers.purpose_options('plate')
    @search_options = OngoingPlate.new(ongoing_plate_search_params)

    @search_results = plate_search.all(
      Limber::Plate,
      @search_options.search_parameters
    )
  end

  def ongoing_tubes
    tube_search = api.search.find(Settings.searches.fetch('Find tubes'))
    @purpose_options = helpers.purpose_options('tube')
    @search_options = OngoingTube.new(ongoing_tube_search_params)

    @search_results = tube_search.all(
      Limber::Tube,
      @search_options.search_parameters
    )
  end

  def qcables
    raise InputError, 'You have not supplied a barcode' if params[:qcable_barcode].blank?
    pruned_barcode = params[:qcable_barcode].strip
    raise InputError, "#{params[:qcable_barcode]} is not a valid barcode" unless /^[0-9]{13}$/.match?(pruned_barcode)
    respond_to do |format|
      format.json do
        redirect_to find_qcable(pruned_barcode)
      end
    end
  rescue Sequencescape::Api::ResourceNotFound, InputError => exception
    render json: { 'error' => exception.message }
  end

  def create
    raise 'You have not supplied a labware barcode' if params[:plate_barcode].blank?
    respond_to do |format|
      format.html { redirect_to find_plate(params[:plate_barcode]) }
    end
  rescue => exception
    @search_results = []
    flash[:error]   = exception.message

    # rendering new without re-searching for the ongoing plates...
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { error: exception.message }, status: 404 }
    end
  end

  def find_plate(barcode)
    machine_barcode =
      if SBCF::HUMAN_BARCODE_FORMAT.match?(barcode)
        SBCF::SangerBarcode.from_human(barcode).machine_barcode
      else
        barcode
      end
    api.search.find(Settings.searches['Find assets by barcode']).first(barcode: machine_barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, "Sorry, could not find labware with the barcode '#{barcode}'."
  end

  def find_qcable(barcode)
    api.search.find(Settings.searches['Find qcable by barcode']).first(barcode: barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, "Sorry, could not find qcable with the barcode '#{barcode}'."
  end

  def retrieve_parent
    parent_plate = api.search.find(Settings.searches['Find source assets by destination asset barcode']).first(barcode: params['barcode'])
    respond_to do |format|
      format.json { render json: { plate: { parent_plate_barcode: parent_plate.barcode.ean13 } } }
    end
  rescue Sequencescape::Api::ResourceNotFound => exception
    respond_to do |format|
      format.json { render json: { 'general' => exception.message }, status: 404 }
    end
  end

  private

  def ongoing_plate_search_params
    params.fetch(:ongoing_plate, {}).permit(:show_my_plates_only, :include_used, plate_purposes: [])
  end

  def ongoing_tube_search_params
    params.fetch(:ongoing_tube, {}).permit(:include_used, tube_purposes: [])
  end
end
