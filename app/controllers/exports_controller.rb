# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  helper ExportsHelper
  before_action :locate_labware, only: :show
  rescue_from Export::NotFound, with: :not_found

  def show
    @page = params.fetch(:page, 0).to_i
    @workflow = export.workflow
    @ancestor_plate = locate_ancestor

    set_filename if export.filename

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
    @labware = @plate = Sequencescape::Api::V2.plate_with_custom_includes(include_parameters,
                                                                          barcode: params[:limber_plate_id])
  end

  def locate_ancestor
    return nil if export.ancestor_purpose.blank?

    ancestor_result = @plate.ancestors.where(purpose_name: export.ancestor_purpose).first
    return nil if ancestor_result.blank?

    Sequencescape::Api::V2.plate_with_custom_includes(include_parameters, id: ancestor_result.id)
  end

  def include_parameters
    export.plate_includes || 'wells'
  end

  def set_filename
    filename = export.csv
    filename += "_#{@labware.human_barcode}" if export.filename['include_barcode']
    filename += "_#{@page + 1}" if export.filename['include_page']
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.csv\""
  end
end
