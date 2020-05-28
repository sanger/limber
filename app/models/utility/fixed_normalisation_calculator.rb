# frozen_string_literal: true

module Utility
  # Handles the Computations for Fixed Normalisation plate creation.
  class FixedNormalisationCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    # Calculates the well amounts (ng) from the well concentrations and a volume multiplication factor.
    def compute_well_amounts(wells) # rubocop:todo Metrics/AbcSize
      # sort on well coordinate to ensure wells are in plate column order
      wells.sort_by(&:coordinate).each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # check for well concentration value present
        if well.latest_concentration.blank?
          errors.add(:base, "Well #{well.location} does not have a concentration, cannot calculate amount in well")
          next
        end

        # concentration recorded is ng per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = well.latest_concentration.value.to_f * source_multiplication_factor
      end
    end

    # Compute the well transfers hash from the parent plate
    def compute_well_transfers(parent_plate, filtered_wells)
      well_amounts = compute_well_amounts(filtered_wells)
      build_transfers_hash(well_amounts, parent_plate.number_of_rows)
    end

    private

    # Build the well transfers hash from the well amounts
    def build_transfers_hash(well_amounts, number_of_rows)
      compressor = Compressor.new(number_of_rows)

      well_amounts.each_with_object({}) do |(well_locn, amount), transfers_hash|
        dest_conc = (amount / dest_multiplication_factor)
        transfers_hash[well_locn] = { 'dest_locn' => WellHelpers.well_name(compressor.row, compressor.column),
                                      'dest_conc' => dest_conc.to_s }

        compressor.next_well_location
      end
    end
  end
end
