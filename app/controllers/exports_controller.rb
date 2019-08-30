# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  before_action :locate_labware, only: :show
  rescue_from ActionView::MissingTemplate, with: :not_found

  TRANSFER_INCLUDES = 'wells.transfer_requests_as_target.source_asset'

  PLATE_INCLUDES = {
    'concentrations_ngul' => 'wells.qc_results',
    'concentrations_nm' => 'wells.qc_results',
    'hamilton_aggregate_cherrypick' => TRANSFER_INCLUDES,
    'hamilton_cherrypick_to_sample_dilution' => TRANSFER_INCLUDES,
    'hamilton_gex_dil_to_gex_frag_2xp' => TRANSFER_INCLUDES,
    'hamilton_gex_frag_2xp_to_gex_ligxp' => TRANSFER_INCLUDES,
    'hamilton_cherrypick_to_5p_gex_dilution' => TRANSFER_INCLUDES,
    'hamilton_cherrypick_to_bcr_dilution1' => TRANSFER_INCLUDES,
    'hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri' => TRANSFER_INCLUDES,
    'hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri' => TRANSFER_INCLUDES,
    'hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2' => TRANSFER_INCLUDES,
    'hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri' => TRANSFER_INCLUDES,
    'hamilton_cherrypick_to_tcr_dilution1' => TRANSFER_INCLUDES,
    'hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri' => TRANSFER_INCLUDES,
    'hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri' => TRANSFER_INCLUDES,
    'hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2' => TRANSFER_INCLUDES,
    'hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri' => TRANSFER_INCLUDES
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
