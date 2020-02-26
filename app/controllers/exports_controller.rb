# frozen_string_literal: true

require 'csv'

# The exports controller handles the generation of exported files,
# such as CSV files used to drive robots.
class ExportsController < ApplicationController
  before_action :locate_labware, only: :show
  rescue_from ActionView::MissingTemplate, with: :not_found

  WELL_QC_INCLUDES = 'wells.qc_results'
  WELL_SRC_ASSET_INCLUDES = 'wells.transfer_requests_as_target.source_asset'

  CSVDetail = Struct.new(:csv, :plate_includes, :workflow) do
  end

  CSV_DETAILS = {
    'concentrations_ngul' =>
      CSVDetail.new('concentrations_ngul', WELL_QC_INCLUDES, nil),
    'duplex_seq_al_lib_concentrations_for_customer' =>
      CSVDetail.new('duplex_seq_al_lib_concentrations_for_customer', WELL_QC_INCLUDES, nil),
    'concentrations_nm' =>
      CSVDetail.new('concentrations_nm', WELL_QC_INCLUDES, nil),
    'hamilton_aggregate_cherrypick' =>
      CSVDetail.new('hamilton_aggregate_cherrypick', WELL_SRC_ASSET_INCLUDES, 'Cherry Pick'),
    'hamilton_cherrypick_to_sample_dilution' =>
      CSVDetail.new('hamilton_fixed_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_gex_dil_to_gex_frag_2xp' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X Post Repair Double SPRI'),
    'hamilton_gex_frag_2xp_to_gex_ligxp' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X Post Ligation Single SPRI'),
    'hamilton_cherrypick_to_5p_gex_dilution' =>
      CSVDetail.new('hamilton_variable_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_cherrypick_to_bcr_dilution1' =>
      CSVDetail.new('hamilton_fixed_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Target Enrichment 1 Single SPRI'),
    'hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Target Enrichment 2 Double SPRI'),
    'hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2' =>
      CSVDetail.new('hamilton_variable_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Ligation SPRI'),
    'hamilton_cherrypick_to_tcr_dilution1' =>
      CSVDetail.new('hamilton_fixed_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Target Enrichment 1 Single SPRI'),
    'hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Target Enrichment 2 Double SPRI'),
    'hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2' =>
      CSVDetail.new('hamilton_variable_volume_dilutions', WELL_SRC_ASSET_INCLUDES, 'Sample Dilution'),
    'hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri' =>
      CSVDetail.new('hamilton_plate_stamp', WELL_SRC_ASSET_INCLUDES, '10X VDJ Post Ligation SPRI')
  }.freeze

  def show
    @workflow = csv_details.workflow
    render csv_details.csv
  end

  def csv_details
    CSV_DETAILS[params[:id]] || not_found
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
    csv_details.plate_includes || 'wells'
  end
end
