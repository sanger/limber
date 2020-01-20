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

        # don't select wells that don't appear in the submission (i.e. automatic cherry pick)
        next unless well.requests_as_source.any? do |req|
          # library type in request must match to that in purposes yml, and request state must be pending
          req.library_type == config.library_type && req.state == 'pending'
        end

        # concentration recorded is ng per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = well.latest_concentration.value.to_f * source_multiplication_factor
      end
    end

    # Compute the well transfers hash from the parent plate
    def compute_well_transfers(parent_plate)
      well_amounts = compute_well_amounts(parent_plate)
      build_transfers_hash(well_amounts, parent_plate.number_of_rows)
    end

    private

    # Build the well transfers hash from the well amounts
    def build_transfers_hash(well_amounts, number_of_rows)
      compressor = Compressor.new(number_of_rows)

      well_amounts.each_with_object({}) do |(well_locn, amount), transfers_hash|
        dest_conc = (amount / dest_multiplication_factor)
        transfers_hash[well_locn] = { 'dest_locn' => WellHelpers.well_name(compressor.row, compressor.column), 'dest_conc' => dest_conc.to_s }

        compressor.next_well_location
      end
    end
  end
end
