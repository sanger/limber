# frozen_string_literal: true

module Utility
  # Handles the Computations for PCR Cycles binning.
  # Used by the PCR Cycles Binned Plate class to handle the binning processing.
  class PcrCyclesBinningCalculator
    include ActiveModel::Model

    # def initialize(config)
    #   @config = Utility::PcrCyclesDilutionsConfig.new(config)
    # end

    # TODO: do we need to pass in anything here? is any configuration required?
    def initialize
    end

    def compute_well_transfers_hash(well_details, number_of_rows, number_of_columns)
      pcr_cycle_bins = pcr_cycle_bins(well_details)
      compression_reqd = compression_required?(pcr_cycle_bins, number_of_rows, number_of_columns)
      build_transfers_hash(pcr_cycle_bins, number_of_rows, compression_reqd)
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
    def pcr_cycle_bins(well_details)
      # TODO: Need to work out how many bins we have ( = distinct pcr_cycle values)
      # TODO: then cycle through adding wells to bins
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(bins, number_of_rows, compression_reqd)
      binner = Binner.new(compression_reqd, number_of_rows)
      bins.values.each_with_object({}).with_index do |(bin, transfers_hash), bin_index_within_bins|
        next if bin.length.zero?

        bin.each_with_index do |well, well_index_within_bin|
          # TODO: what is the structure of this? what fields are needed and do we need to add more fields on transfer requests?
          src_locn = well['locn']
          details = well['details']
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(binner.row, binner.column),
            'volume' => details['source_volume'].to_s
          }
          # work out what the next row and column will be
          finished = ((bin_index_within_bins == bins.size - 1) && (well_index_within_bin == bin.size - 1))
          binner.next_well_location(well_index_within_bin, bin.size) unless finished
        end
      end
    end
  end
end
