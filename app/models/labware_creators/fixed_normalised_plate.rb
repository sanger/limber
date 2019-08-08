# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of fixed normalised plate.
  # This type of plate has a source and diluent volume specified in the purpose configuration.
  # Wells are stamped across without any rearrangements.
  # The child well concentrations are calculated and written as qc_results on the plate.
  class FixedNormalisedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations

    QC_ASSAY_VERSION = 'Fixed Normalisation'

    validate :wells_with_aliquots_have_concentrations?

    # The configuration from the plate purpose.
    # Contains source and diluent volumes used to calculate destination concentrations.
    # def dilutions_config
    #   purpose_config.fetch(:dilutions)
    # end

    def dilutions_calculator
      @dilutions_calculator ||= Utility::FixedNormalisationCalculator.new(dilutions_config)
    end

    private

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => dilutions_calculator.source_volume.to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end

    def dest_well_qc_attributes
      @dest_well_qc_attributes ||=
        dilutions_calculator.construct_dest_qc_assay_attributes(child.uuid, QC_ASSAY_VERSION, transfer_hash)
    end

    def after_transfer!
      Sequencescape::Api::V2::QcAssay.create(
        qc_results: dest_well_qc_attributes
      )
    end
  end
end
