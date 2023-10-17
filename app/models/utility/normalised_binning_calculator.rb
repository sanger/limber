# frozen_string_literal: true

module Utility
  # Handles the Computations for Normalised Binning
  # Used by the Normalised Binned Plate and Presenter classes to handle the
  # normalisation, compute the bins and provide helpers on displaying
  # the bins on the child plate.
  class NormalisedBinningCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    def compute_well_transfers(parent_plate, filtered_wells)
      norm_details = normalisation_details(filtered_wells)
      compute_well_transfers_hash(norm_details, parent_plate.number_of_rows, parent_plate.number_of_columns)
    end

    def compute_well_transfers_hash(norm_details, number_of_rows, number_of_columns)
      conc_bins = concentration_bins(norm_details)
      compression_reqd = compression_required?(conc_bins, number_of_rows, number_of_columns)
      build_transfers_hash(conc_bins, number_of_rows, compression_reqd)
    end

    # Used by the plate presenter. Uses the concentration in the well and the plate purpose config
    # to work out the well bin colour and number of PCR cycles.
    def compute_presenter_bin_details(plate)
      well_amounts = compute_well_amounts_for_presenter(plate)
      compute_bin_details_by_well(well_amounts)
    end

    private

    def compute_well_amounts_for_presenter(plate)
      plate
        .wells_in_columns
        .each_with_object({}) do |well, well_amounts|
          next if well.aliquots.blank?

          # concentration recorded is per microlitre, multiply by volume to get amount in ng in well
          well_amounts[well.location] = well.latest_concentration.value.to_f * config.target_volume
        end
    end

    # Sorts well locations into bins based on their amounts.
    def concentration_bins(norm_details)
      # Returns eg. { 1 => [], 2 => [], 3 => [] }
      conc_bins = (1..number_of_bins).index_with { |_bin_number| [] }
      norm_details.each do |well_locn, details|
        amount = details['amount_in_target']
        bins_template.each_with_index do |bin_template, bin_index|
          next unless (bin_template['min']...bin_template['max']).cover?(amount)

          conc_bins[bin_index + 1] << { 'locn' => well_locn, 'details' => details }
          break
        end
      end
      conc_bins
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(bins, number_of_rows, compression_reqd) # rubocop:todo Metrics/AbcSize
      binner = Binner.new(compression_reqd, number_of_rows)
      bins
        .values
        .each_with_object({})
        .with_index do |(bin, transfers_hash), bin_index_within_bins|
          next if bin.length.zero?

          # TODO: we may want to sort the bin here, e.g. by concentration
          bin.each_with_index do |well, well_index_within_bin|
            src_locn = well['locn']
            details = well['details']
            transfers_hash[src_locn] = {
              'dest_locn' => WellHelpers.well_name(binner.row, binner.column),
              'dest_conc' => details['dest_conc'].to_s,
              'volume' => details['vol_source_reqd'].to_s
            }

            # work out what the next row and column will be
            finished = ((bin_index_within_bins == bins.size - 1) && (well_index_within_bin == bin.size - 1))
            binner.next_well_location(well_index_within_bin, bin.size) unless finished
          end
        end
    end
  end
end
