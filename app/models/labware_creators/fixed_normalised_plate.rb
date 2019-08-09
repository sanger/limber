# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of fixed normalised plate.
  # This type of plate has a source and diluent volume specified in the purpose configuration.
  # Wells are stamped across without any rearrangements.
  # The child well concentrations are calculated and written as qc_results on the plate.
  class FixedNormalisedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQCResults

    validate :wells_with_aliquots_have_concentrations?

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
  end
end
