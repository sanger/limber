# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  before_action :locate_labware, only: :show
  rescue_from Export::NotFound, with: :not_found

  def show
    @workflow = export.workflow
    if export.ancestor_purpose.present?
      ancestor_result = @plate.ancestors.where(purpose_name: export.ancestor_purpose).first
      locate_ancestor(ancestor_result.id) if ancestor_result.present?
    end
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
    @labware = @plate = Sequencescape::Api::V2.plate_with_custom_includes(include_parameters,
                                                                          barcode: params[:limber_plate_id])
  end

  def locate_ancestor(plate_id)
    @ancestor_plate = Sequencescape::Api::V2.plate_with_custom_includes(include_parameters, id: plate_id)
  end

  def include_parameters
    export.plate_includes || 'wells'
  end
end
