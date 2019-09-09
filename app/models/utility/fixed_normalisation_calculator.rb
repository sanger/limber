# frozen_string_literal: true

module Utility
  # Handles the Computations for Fixed Normalisation plate creation.
  class FixedNormalisationCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    # Calculates the well amounts (ng) from the plate well concentrations and a volume multiplication factor.
    def compute_well_amounts(plate)
      plate.wells_in_columns.each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # concentration recorded is ng per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = well.latest_concentration.value.to_f * source_multiplication_factor
      end
    end

    # Compute the well transfers hash from the parent plate
    def compute_well_transfers(parent_plate)
      well_amounts = compute_well_amounts(parent_plate)
      build_transfers_hash(well_amounts)
    end

    private

    # Build the well transfers hash from the well amounts
    def build_transfers_hash(well_amounts)
      well_amounts.each_with_object({}) do |(well_locn, amount), transfers_hash|
        dest_conc = (amount / dest_multiplication_factor)
        transfers_hash[well_locn] = { 'dest_locn' => well_locn, 'dest_conc' => dest_conc.to_s }
      end
    end
  end
end
