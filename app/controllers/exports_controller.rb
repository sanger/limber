# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  include ExportsFilenameBehaviour
  helper ExportsHelper
  before_action :locate_labware, only: :show
  rescue_from Export::NotFound, with: :not_found

  def show
    @page = params.fetch(:page, 0).to_i
    @workflow = export.workflow
    @ancestor_plate = locate_ancestor_plate
    @ancestor_tubes = locate_ancestor_tubes
    @ancestor_plate_list = locate_ancestor_plate_list

    # Set the filename for the export via the ExportsFilenameBehaviour concern
    set_filename(@labware, @page) if export.filename

    render export.csv, locals: { test: 'this' }
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
      @plate = Sequencescape::Api::V2.plate_with_custom_includes(include_parameters, barcode: params[:plate_id])
  end

  def locate_ancestor_plate
    return nil if export.ancestor_purpose.blank?

    ancestor_result = @plate.ancestors.where(purpose_name: export.ancestor_purpose).first
    return nil if ancestor_result.blank?

    Sequencescape::Api::V2.plate_with_custom_includes(include_parameters, id: ancestor_result.id)
  end

  # Returns an array of all ancestor plates of @plate that match a specific
  # purpose (defined in the export configuration). If no such plates are found,
  # an empty array is returned. The result array is made available to the view
  # that generates the export as @ancestor_plate_list by the show method.
  #
  # @return [Array, Sequencescape::Api::V2::Plate] An array of Plate records if
  #   any are found, otherwise an empty array.
  def locate_ancestor_plate_list
    return [] if export.ancestor_purpose.blank?

    # Collect plate ids from the polymorphic Sequencescape::Api::V2::Asset
    # polymorphic results to fetch the plates.
    ids = @plate.ancestors.where(purpose_name: export.ancestor_purpose).map(&:id)
    return [] if ids.empty?

    Sequencescape::Api::V2::Plate.includes(include_parameters).find({ id: ids })
  end

  def include_parameters
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

    ancestor_results = @plate.ancestors.where(purpose_name: export.ancestor_tube_purpose)
    return nil if ancestor_results.blank?

    # create hash of sample uuid to tube
    ancestor_tube_details(ancestor_results)
  end
end
