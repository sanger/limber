# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  before_action :locate_labware, only: :show
  rescue_from ActionView::MissingTemplate, with: :not_found

  PLATE_INCLUDES = {
    'concentrations_ngul' => 'wells.qc_results',
    'concentrations_nm' => 'wells.qc_results',
    'hamilton_aggregate_cherrypick' => 'wells.transfer_requests_as_target.source_asset'
  }.freeze

  def show
    render params[:id]
  end

  private

  def not_found
    raise ActionController::RoutingError, "Unknown template #{params[:id]}"
  end

  def configure_api
    # We don't use the V1 Sequencescape API here, so lets disable its initialization.
    # Probably should consider two controller classes as this expands.
  end

  def locate_labware
    @labware = @plate = Sequencescape::Api::V2.plate_with_custom_includes(include_parameters, barcode: params[:limber_plate_id])
  end

  def include_parameters
    PLATE_INCLUDES[params[:id]] || 'wells'
  end
end
