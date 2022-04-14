# frozen_string_literal: true

module Utility
  # Handles the Computations for PCR Cycles binning.
  # Used by the PCR Cycles Binned Plate class to handle the binning processing.
  class PcrCyclesBinningCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    def initialize(well_details)
      @well_details = well_details
    end

    def compute_well_transfers(parent_plate)
      bins_hash = pcr_cycle_bins
      compression_reqd = compression_required?(bins_hash, parent_plate.number_of_rows, parent_plate.number_of_columns)
      build_transfers_hash(bins_hash, parent_plate.number_of_rows, compression_reqd)
    end

    def presenter_bins_key
      # fetch the array of bins as pcr cycles e.g. [16,14,12]
      bins = calculate_bins

      # dynamic number of bins so count the colours up from 1
      colour_index = 1
      bins.each_with_object([]) do |bin, templates|
        templates << { 'colour' => colour_index, 'pcr_cycles' => bin }
        colour_index += 1
      end
    end

    def compute_presenter_bin_details
      @well_details.each_with_object({}) do |(well_locn, well_detail), bin_dets|
        presenter_bins_key.each do |bin|
          next unless well_detail['pcr_cycles'] == bin['pcr_cycles']

          bin_dets[well_locn] = { 'colour' => bin['colour'], 'pcr_cycles' => bin['pcr_cycles'] }
        end
      end
    end

    private

    def calculate_bins
      bins = []
      @well_details.each do |_well_locn, details|
        pcr_cycles = details['pcr_cycles']
        bins << pcr_cycles unless bins.include? pcr_cycles
      end

      # want pcr cycle bins in reverse order, highest first e.g. [16,14,12]
      bins.sort.reverse
    end

    # Sorts well locations into bins based on their number of pcr cycles.
    def pcr_cycle_bins
      pcr_bins = calculate_bins

      # Generates a hash with each value in pcr_bins as a key, and [] as a value
      binned_wells = pcr_bins.index_with { |_bin_pcr_cycles_num| [] }
      @well_details.each do |well_locn, details|
        pcr_cycles_num = details['pcr_cycles']
        binned_wells[pcr_cycles_num] << { 'locn' => well_locn, 'sample_volume' => details['sample_volume'] }
      end
      binned_wells
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(bins, number_of_rows, compression_reqd)
      binner = Binner.new(compression_reqd, number_of_rows)
      bins
        .values
        .each_with_object({})
        .with_index do |(bin, transfers_hash), bin_index_within_bins|
          bin.each_with_index do |well, well_index_within_bin|
            build_transfers_well(binner, transfers_hash, well)
            binner_next_well(binner, bins, bin, bin_index_within_bins, well_index_within_bin)
          end
        end
    end

    def build_transfers_well(binner, transfers_hash, well)
      src_locn = well['locn']
      transfers_hash[src_locn] = {
        'dest_locn' => WellHelpers.well_name(binner.row, binner.column),
        'volume' => well['sample_volume'].to_s
      }
    end

    # work out what the next row and column will be
    def binner_next_well(binner, bins, bin, bin_index_within_bins, well_index_within_bin)
      finished = ((bin_index_within_bins == bins.size - 1) && (well_index_within_bin == bin.size - 1))
      binner.next_well_location(well_index_within_bin, bin.size) unless finished
    end
  end
end
