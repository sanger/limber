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
      @tube =
        Sequencescape::Api::V2.tube_with_custom_includes(
          include_parameters,
          select_parameters,
          barcode: params[:limber_tube_id]
        )
  end

  def include_parameters
    export.tube_includes || nil
  end

  # Returns the parameters specified for Sparse Fieldsets
  # https://github.com/JsonApiClient/json_api_client
  # https://jsonapi.org/format/#fetching-sparse-fieldsets
  def select_parameters
    export.tube_selects || nil
  end

  def set_filename
    # The filename falls back to the csv template attribute if no filename is provided.
    filename = export.filename['name'] || export.csv
    filename = build_filename(filename)
    file_extension = export.file_extension || 'csv'
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.#{file_extension}\""
  end

  def build_filename(filename)
    # Append or prepend the give barcodes to the filename if specified in the export configuration.
    filename = handle_filename_barcode(filename, @labware, export.filename['labware_barcode'])
    filename = handle_filename_barcode(filename, @labware.parents.first, export.filename['parent_labware_barcode'])
    # Append the page number to the filename if specified in the export configuration.
    filename += "_#{@page + 1}" if export.filename['include_page']
    filename
  end

  def handle_filename_barcode(filename, labware, options)
    return filename if options.blank? || labware.blank?

    barcode = labware.human_barcode
    filename = "#{barcode}_#{filename}" if options['prepend']
    filename = "#{filename}_#{barcode}"if options['append']
    filename
  end
end
