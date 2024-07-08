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

    # Returns the second replicate wells in the plate. It groups the filtered
    # wells by the ancestor tube barcode and returns the second well in each
    # group.
    def second_replicates
      barcode_counts = Hash.new(0) # Initializes a new hash to count barcode occurrences
      filtered_wells
        .each_with_object({}) do |well, hash|
          barcode = ancestor_barcode(well)
          barcode_counts[barcode] += 1

          # Update the hash with the well when the barcode is encountered the second time
          hash[barcode] = well if barcode_counts[barcode] == 2
        end
        .values
    end

    private

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
