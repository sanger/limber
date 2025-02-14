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
    @ancestor_tubes = locate_ancestor_tubes

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

    return if @tube_rack.blank?

    # We need to get the plate to be able to access both Tube Racks
    # for the LRC PBMC Bank plate split driver file
    @plate =
      Sequencescape::Api::V2.plate_with_custom_includes(
        plate_include_parameters,
        barcode: @tube_rack.ancestors.last.barcode.human
      )
  end

  def include_parameters
    export.tube_rack_includes || 'racked_tubes'
  end

  def select_parameters
    export.tube_rack_selects || nil
  end

  def plate_include_parameters
    export.plate_includes || 'wells'
  end

  def ancestor_tube_details(ancestor_results)
    ancestor_results.each_with_object({}) do |ancestor_result, tube_list|
      tube = Sequencescape::Api::V2::Tube.find_by(uuid: ancestor_result.uuid)
      tube_sample_uuid = tube.aliquots.first.sample.uuid
      tube_list[tube_sample_uuid] = tube if tube_sample_uuid.present?
    end
  end

  def locate_ancestor_tubes
    return nil if export.ancestor_tube_purpose.blank?

    ancestor_results = @tube_rack.ancestors.where(purpose_name: export.ancestor_tube_purpose)
    return nil if ancestor_results.blank?

    # create hash of sample uuid to tube
    ancestor_tube_details(ancestor_results)
  end
end
