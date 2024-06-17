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
      count ||= ancestor_tubes.size
      select_wells_until([count, ancestor_tubes.size].min)
    end

    # Selects wells until the specified count is reached or all bins of wells
    # are exhausted. The method ensures the selected wells that are distributed
    # across the plate.
    #
    # @param count [Integer] number of wells to select
    # @return [Array<Well>] an array of selected Well objects
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
    # number of wells to select. Empty wells are rejected. This is used for
    # picking wells that are distributed across the plate.
    #
    # @param count [Integer] the number of wells to select
    # @return [Array<Array<Well>>] bins of wells to cycle selection
    def prepare_bins(count)
      wells = plate.wells_in_columns.reject(&:empty?)
      bin_size = (wells.length / count.to_f).ceil
      wells.each_slice(bin_size).to_a
    end
  end
end
