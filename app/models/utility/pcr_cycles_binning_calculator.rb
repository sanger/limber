# frozen_string_literal: true

module Utility
  # Handles the Computations for PCR Cycles binning.
  # Used by the PCR Cycles Binned Plate class to handle the binning processing.
  class PcrCyclesBinningCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    def initialize(request_metadata_details)
      @request_metadata_details = request_metadata_details
    end

    def compute_well_transfers(parent_plate)
      compression_reqd =
        compression_required?(binned_well_details, parent_plate.number_of_rows, parent_plate.number_of_columns)
      build_transfers_hash(parent_plate.number_of_rows, compression_reqd)
    end

    def presenter_bins_key
      # dynamic number of bins so count the colours up from 1
      colour_index = 1
      bins.each_with_object([]) do |bin, templates|
        templates << { 'colour' => colour_index, 'pcr_cycles' => bin }
        colour_index += 1
      end
    end

    def compute_presenter_bin_details
      @request_metadata_details.each_with_object({}) do |(well_locn, well_detail), bin_dest|
        presenter_bins_key.each do |bin|
          next unless well_detail['pcr_cycles'] == bin['pcr_cycles']

          bin_dest[well_locn] = { 'colour' => bin['colour'], 'pcr_cycles' => bin['pcr_cycles'] }
        end
      end
    end

    private

    def bins
      @bins ||= calculate_distinct_bins
    end

    # Create the array of bins by number of pcr cycles
    # Want pcr cycle bins in reverse order, highest first
    # e.g. [16,14,12]
    def calculate_distinct_bins
      @request_metadata_details
        .each_with_object([]) do |(_well_locn, details), calculated_bins|
          num_pcr_cycles = details['pcr_cycles']
          calculated_bins << num_pcr_cycles unless calculated_bins.include? num_pcr_cycles
        end
        .sort
        .reverse
    end

    def binned_well_details
      @binned_well_details ||= populate_bins_by_pcr_cycles
    end

    # Sorts well details into bins based on their number of pcr cycles.
    # e.g.
    # {
    #   16: [
    #     { 'locn': 'A1', 'sample_volume': 5.4 },
    #     { 'locn': 'C1', 'sample_volume': 3.5 },
    #   ],
    #   14: [
    #     { 'locn': 'B1', 'sample_volume': 5.4 },
    #   ], etc.
    # }
    def populate_bins_by_pcr_cycles
      # initializes a hash with each value in bins as a key, and [] as a value
      binned_wells = bins.index_with { |_bin_pcr_cycles_num| [] }

      # then cycle through the request metadata and the hash of values needed
      @request_metadata_details.each do |well_locn, details|
        pcr_cycles_num = details['pcr_cycles']
        binned_wells[pcr_cycles_num] << { 'locn' => well_locn, 'sample_volume' => details['sample_volume'] }
      end
      binned_wells
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    # e.g.
    # {
    #   "A1"=>{"dest_locn"=>"H2", "volume"=>"5.0"},
    #   "A2"=>{"dest_locn"=>"H1", "volume"=>"3.2"},
    #   etc.
    # }
    def build_transfers_hash(number_of_rows, compression_reqd)
      binner = Binner.new(compression_reqd, number_of_rows)
      binned_well_details
        .values
        .each_with_object({})
        .with_index do |(bin, transfers_hash), bin_index_within_bins|
          bin.each_with_index do |well, well_index_within_bin|
            build_transfers_well(binner, transfers_hash, well)
            binner_next_well(binner, bin, bin_index_within_bins, well_index_within_bin)
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
    def binner_next_well(binner, bin, bin_index_within_bins, well_index_within_bin)
      finished = ((bin_index_within_bins == binned_well_details.size - 1) && (well_index_within_bin == bin.size - 1))
      binner.next_well_location(well_index_within_bin, bin.size) unless finished
    end
  end
end
