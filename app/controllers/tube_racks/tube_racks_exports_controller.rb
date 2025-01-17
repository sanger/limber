# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files for tube racks
class TubeRacks::TubeRacksExportsController < ApplicationController
  include ExportsFilenameBehaviour
  # helper ExportsHelper
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

  def configure_api
    # We don't use the V1 Sequencescape API here, so lets disable its initialization.
    # Probably should consider two controller classes as this expands.
  end

  def locate_labware
    @labware =
      @tube_rack =
        Sequencescape::Api::V2.tube_rack_with_custom_includes(
          include_parameters,
          select_parameters,
          uuid: params[:limber_tube_rack_id]
        )
  end

  def include_parameters
    export.tube_rack_includes || nil
  end

  def select_parameters
    export.tube_rack_selects || nil
  end
end
