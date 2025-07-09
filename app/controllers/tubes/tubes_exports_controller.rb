# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files for tubes,
# such as CSV files for mbrave files.
class Tubes::TubesExportsController < ApplicationController
  include ExportsFilenameBehaviour
  helper ExportsHelper
  before_action :locate_labware, only: :show
  rescue_from Export::NotFound, with: :not_found

  def show
    @page = params.fetch(:page, 0).to_i
    @workflow = export.workflow

    # Set the filename for the export via the ExportsFilenameBehaviour concern
    set_filename(@labware, @page) if export.filename

    render export.csv
  end

  private

  def export
    @export ||= Export.find(params[:id])
  end

  def not_found
    raise ActionController::RoutingError, "Unknown template #{params[:id]}"
  end

  def locate_labware
    @labware =
      @tube =
        Sequencescape::Api::V2.tube_with_custom_includes(
          include_parameters,
          select_parameters,
          barcode: params[:tube_id]
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
end
