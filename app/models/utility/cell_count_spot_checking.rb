# frozen_string_literal: true

module Utility
  # This class is used to select wells from a plate for spot checking.
  class CellCountSpotChecking
    attr_reader :plate, :ancestor_tubes

    # Initializes the object with a plate and its ancestor tubes. It is used
    # to pick wells from the plate for spot checking.
    #
    # @param plate [Plate] the plate associated with this instance
    # @param ancestor_tubes [Array<Tube>] the ancestor tubes of the plate
    def initialize(plate, ancestor_tubes)
      @plate = plate
      @ancestor_tubes = ancestor_tubes
    end

    # Selects at most the specified number of wells from the plate. If the
    # number of ancestor tubes is less than the count, or it the count is
    # not specified it selects one well per ancestor tube.
    #
    # @param count [Integer] the number of wells to select
    # @return [Array<Well>] an array of selected Well objects
    def select_wells(count = nil)
      size = ancestor_tubes.size
      count ||= size
      select_wells_until([count, size].min)
    end

    private

    # Selects wells until the specified count is reached or all bins of wells
    # are exhausted. The method ensures the selected wells that are distributed
    # across the plate.
    #
    # @param count [Integer] number of wells to select
    # @return [Array<Well>] an array of selected Well objects
    # :reek:FeatureEnvy
    def select_wells_until(count)
      bins = prepare_bins(count)
      selected = {}
      process_bins(count, bins, selected) while selected.size < count || bins.any?(&:any?)
      selected.values
    end

    # Processes bins to select wells until the specified count is reached. It
    # iterates over each bin, pops the first well, and puts the UUID of its
    # first sample into the selected hash if it is not already there. it stops
    # if the selected size reaches the count.
    #
    # @param count [Integer] the number of wells to select
    # @param bins [Array<Array<Well>>] the bins of wells to select from
    # @param selected [Hash{String => Well}] tracks wells already selected
    # @return [void]
    # :reek:FeatureEnvy
    # :reek:TooManyStatements
    # :reek:UtilityFunction { public_methods_only: true }
    def process_bins(count, bins, selected)
      bins.each do |bin|
        next if bin.empty?
        well = bin.shift
        uuid = well.aliquots.first.sample.uuid
        selected[uuid] = well unless selected.key?(uuid)
        break if selected.size >= count
      end
    end

    # Prepares bins of wells by based on the specified count which is the
    # number of wells to select. Empty wells are rejected. It is used for
    # picking wells that are distributed across the plate. It adds the last
    # well to its own bin for maximum spread.
    #
    # @param count [Integer] the number of wells to select
    # @return [Array<Array<Well>>] bins of wells to cycle selection
    # :reek:FeatureEnvy
    def prepare_bins(count)
      wells = plate.wells_in_columns.reject(&:empty?)
      size = wells.size

      return [] if size.zero? || count.zero? # no wells to select

      return [[wells.first]] if size == 1 || count == 1 # one well to select

      # Add the last well to its own bin for maximum spread.
      wells[0...-1].each_slice(bin_size_excluding_last(size, count)).to_a << [wells.last]
    end

    # Calculates the bin size excluding the last well from the count.
    #
    # @param count [Integer] the number wells to select
    # @param size [Integer] the number of wells in the plate
    # @return [Integer] the bin size
    # :reek:UtilityFunction { public_methods_only: true }
    def bin_size_excluding_last(size, count)
      (size / (count - 1).to_f).ceil
    end
  end
end
