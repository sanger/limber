# frozen_string_literal: true

module Utility
  # Handles the Computations for Concentration Normalisation.
  # Used by the Concentration Normalised Plate class to handle the
  # normalisation processing.
  class ConcentrationNormalisationCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    def compute_well_transfers(plate)
      norm_details = normalisation_details(plate)
      build_transfers_hash(norm_details)
    end

    private

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(norm_details)
      norm_details.each_with_object({}) do |(well_locn, details), transfers_hash|
        transfers_hash[well_locn] = {
          'dest_locn' => well_locn,
          'dest_conc' => details['dest_conc'].to_s,
          'volume' => details['vol_source_reqd'].to_s
        }
      end
    end
  end
end
