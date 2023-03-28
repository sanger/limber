# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files for tubes,
# such as CSV files for mbrave files.
class Tubes::TubesExportsController < ApplicationController
  helper ExportsHelper
  before_action :locate_labware, only: :show
  rescue_from Export::NotFound, with: :not_found

  def show
    @page = params.fetch(:page, 0).to_i
    @workflow = export.workflow

    set_filename if export.filename

    render export.csv
  end

  private

  def export
    @export ||= Export.find(params[:id])
  end

  def not_found
    raise ActionController::RoutingError, "Unknown template #{params[:id]}"
  end

  def configure_api
    # We don't use the V1 Sequencescape API here, so lets disable its initialization.
    # Probably should consider two controller classes as this expands.
  end

  def locate_labware
    @labware =
      @tube = Sequencescape::Api::V2.tube_with_custom_includes(include_parameters, barcode: params[:limber_tube_id])
  end

  def include_parameters
    export.tube_includes || nil
  end

  def set_filename
    filename = export.csv
    filename += "_#{@labware.human_barcode}" if export.filename['include_barcode']
    filename += "_#{@page + 1}" if export.filename['include_page']
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.csv\""
  end

end
