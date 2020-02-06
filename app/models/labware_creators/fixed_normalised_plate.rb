# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of fixed normalised plate.
  # This type of plate has a source and diluent volume specified in the purpose configuration.
  # Wells are stamped across without any rearrangements.
  # The child well concentrations are calculated and written as qc_results on the plate.
  class FixedNormalisedPlate < PartialStampedPlate
    def dilutions_calculator
      @dilutions_calculator ||= Utility::FixedNormalisationCalculator.new(dilutions_config)
    end
  end
end
