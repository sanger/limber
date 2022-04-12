# frozen_string_literal: true

# Can be included in plate creators which require qc_results inserted on the new plate.
module LabwareCreators::GenerateQcResults
  extend ActiveSupport::Concern

  private

  def dest_well_qc_attributes
    @dest_well_qc_attributes ||=
      dilutions_calculator.construct_dest_qc_assay_attributes(child.uuid, transfer_hash)
  end

  def after_transfer!
    Sequencescape::Api::V2::QcAssay.create(
      qc_results: dest_well_qc_attributes
    )
  end
end
