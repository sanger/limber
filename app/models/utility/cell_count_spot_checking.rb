# frozen_string_literal: true

module Utility
  # This class is used to select wells from a plate for spot checking.
  # NB. It assumes that the barcodes of the ancestor tubes are stored in the
  # sample metadata supplier_name field.
  class CellCountSpotChecking
    attr_reader :plate, :ancestor_tubes

    # Initializes the object with a plate. It is use to pick wells from the
    # plate for spot checking.
    #
    # @param plate [Plate] the plate associated with this instance
    def initialize(plate)
      @plate = plate
    end

    # Returns the number of ancestor tubes associated with the plate. It finds
    # the number of unique supplier names in the sample metadata of the first
    # sample in each well.
    #
    # @return [Integer] the number of ancestor tubes
    def ancestor_tubes_size
      @ancestor_tubes_size ||= filtered_wells.map { |well| ancestor_barcode(well) }.uniq.size
    end

    # Selects at most the specified number of wells from the plate. If the
    # number of ancestor tubes is less than the count, or if the count is
    # not specified, it selects one well per ancestor tube.
    #
    # @param count [Integer] the number of wells to select
    # @return [Array<Well>] an array of selected Well objects
    def select_wells(count = nil)
      count ||= ancestor_tubes_size
      select_wells_until([count, ancestor_tubes_size].min)
    end

    private

    # Selects wells until the specified count is reached or all bins of wells
    # are exhausted. The method ensures the selected wells that are distributed
    # across the plate. The result is sorted by well coordinates, column-major.
    #
    # @param count [Integer] number of wells to select
    # @return [Array<Well>] an array of selected Well objects
    #
    # :reek:FeatureEnvy
    def select_wells_until(count)
      bins = prepare_bins(count)
      selected = {} # vac_tube_barcode => well
      process_bins(count, bins, selected) while selected.size < count && bins.any?(&:any?)
      selected.values.sort_by(&:coordinate)
    end

    # Processes bins to select wells until the specified count is reached. It
    # iterates over each bin, pops the first well, and puts the barcode of the
    # vac tube of the first sample in the selected hash if it is not already
    # there. it stops if the selected size reaches the count.
    #
    # @param count [Integer] the number of wells to select
    # @param bins [Array<Array<Well>>] the bins of wells to select from
    # @param selected [Hash{String => Well}] tracks wells already selected
    # @return [void]
    #
    # :reek:FeatureEnvy
    # :reek:TooManyStatements
    def process_bins(count, bins, selected)
      bins.each do |bin|
        next if bin.empty?
        well = bin.shift
        barcode = ancestor_barcode(well)
        selected[barcode] = well unless selected.key?(barcode)
        break if selected.size >= count
      end
    end

    # Prepares bins of wells based on the specified count, which is the number
    # of wells to select. Empty wells are rejected. It is used for picking
    # wells that are distributed across the plate. It adds the last well to its
    # own bin for maximum spread. It is added to the first bin to make sure it
    # is searched first.
    #
    # @param count [Integer] the number of wells to select
    # @return [Array<Array<Well>>] bins of wells to cycle selection
    #
    # :reek:FeatureEnvy
    # :reek:TooManyStatements
    def prepare_bins(count)
      wells = first_replicates
      return [] if wells.empty? || count.zero?
      return [[wells.first]] if wells.one? || count == 1

      bins = distribute_wells_evenly(wells[0...-1], count - 1)
      bins.unshift([wells.last]) # Add the last well to its own bin at the beginning
      bins
    end

    # Distributes wells evenly across the specified number of bins. This method
    # is called by prepare_bins and it handles the distribution of wells except
    # the last one, which will be added to its own bin by the caller.
    #
    # @param wells [Array<Well>] the wells to distribute
    # @param bin_count [Integer] the number of bins to distribute the wells
    # @return [Array<Array<Well>>] bins of wells to cycle selection
    #
    # :reek:TooManyStatements
    # :reek:UtilityFunction { public_methods_only: true }
    def distribute_wells_evenly(wells, bin_count)
      adjusted_size = wells.size
      base_bin_size = adjusted_size / bin_count
      remainder = adjusted_size % bin_count

      bins = []
      start_index = 0

      bin_count.times do |index|
        # Add an extra well to the bin if there is a remainder that can be used
        end_index = start_index + base_bin_size + (index < remainder ? 1 : 0)
        bins << wells[start_index...end_index]
        start_index = end_index
      end

      bins
    end

    # Returns the first replicate wells in the plate. It groups the filtered
    # wells by the ancestor tube barcode and returns the first well in each
    # group.
    #
    # @return [Array<Well>] the first replicate wells in the plate
    def first_replicates
      filtered_wells
        .each_with_object({}) do |well, hash|
          barcode = ancestor_barcode(well)
          hash[barcode] ||= well
        end
        .values
    end

    # Returns the wells in the plate that are not empty in column-major order.
    #
    # @return [Array<Well>] the wells in the plate that are not empty
    def filtered_wells
      @filtered_wells ||= plate.wells_in_columns.reject(&:empty?)
    end

    # Returns the barcode of the ancestor tube associated with the well from
    # the sample metadata supplier_name field.
    #
    # @param well [Well] the well to get the ancestor tube barcode
    # @return [String] the barcode of the ancestor tube
    #
    # :reek:UtilityFunction { public_methods_only: true }
    def ancestor_barcode(well)
      well.aliquots.first.sample.sample_metadata.supplier_name
    end
  end
end
