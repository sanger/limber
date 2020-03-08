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

    # Used by the plate presenter. Uses the well metadata to work out the well bin colour and number of PCR cycles.
    # def compute_presenter_bin_details(plate)
    #   well_pcr_cycles = fetch_well_pcr_cycles_for_presenter(plate)
    #   compute_bin_details_by_well(well_pcr_cycles)
    # end

    private

    # def fetch_well_pcr_cycles_for_presenter(plate)
    #   plate.wells_in_columns.each_with_object({}) do |well, well_pcr_cycles|
    #     next if well.aliquots.blank?

    #     # fetch pcr cycles per well
    #     well_pcr_cycles[well.location] = well.metadata.pcr_cycles # TODO: or should we store bin number in metadata too?
    #   end
    # end

    # Sorts well locations into bins based on their number of pcr cycles.
    def pcr_cycle_bins
      pcr_bins = calculate_bins
      binned_wells = pcr_bins.each_with_object({}) { |bin_pcr_cycles_num, bins_hash| bins_hash[bin_pcr_cycles_num] = [] }
      @well_details.each do |well_locn, details|
        pcr_cycles_num = details['pcr_cycles']
        binned_wells[pcr_cycles_num] << { 'locn' => well_locn, 'sample_volume' => details['sample_volume'] }
      end
      binned_wells
    end

    def calculate_bins
      bins = []
      @well_details.each do |well_locn, details|
        pcr_cycles = details['pcr_cycles']
        bins << pcr_cycles unless bins.include? pcr_cycles
      end
      # want pcr cycle bins in reverse order, highest first e.g. [16,14,12]
      bins.sort.reverse
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(bins, number_of_rows, compression_reqd)
      binner = Binner.new(compression_reqd, number_of_rows)
      bins.values.each_with_object({}).with_index do |(bin, transfers_hash), bin_index_within_bins|
        bin.each_with_index do |well, well_index_within_bin|
          src_locn = well['locn']
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(binner.row, binner.column),
            'volume' => well['sample_volume'].to_s
          }
          # work out what the next row and column will be
          finished = ((bin_index_within_bins == bins.size - 1) && (well_index_within_bin == bin.size - 1))
          binner.next_well_location(well_index_within_bin, bin.size) unless finished
        end
      end
    end
  end
end
