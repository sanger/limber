# frozen_string_literal: true

module LabwareCreators
  # This creator takes all the wells from the parent plate and compresses them to the top-left
  # of the child plate. It uses the standard well filter.
  class StampedPlateCompressed < StampedPlate
    # Returns the lists of wells from the parent labware in column order, i.e.,
    # A1, B1, ... H1, A2, B2, ... etc. This method is invoked by well_filter.
    # The order of wells returned by the 'filtered' method of the well_filter
    # is influenced by the order of wells returned by this method.
    #
    # @return [Array<Well>] the wells of the parent labware in column order.
    #
    def labware_wells
      parent.wells_in_columns
    end

    # Returns an array of the filtered parent wells.
    #
    # @return [Array<Well>] the filtered wells of the parent
    #
    def parent_wells_to_transfer
      well_filter.filtered.map(&:first)
    end

    # Returns the destination location for a given source well. The index of
    # the source well in the array of parent wells to transfer (after filtering)
    # is used to calculate the destination. This is because wells are compressed
    # to the top-left on the child plate.
    #
    # @param source_well [Well] the source well
    # @return [String] the destination location
    #
    def get_destination_location(source_well)
      index = parent_wells_to_transfer.index(source_well)
      WellHelpers.well_at_column_index(index)
    end

    # Returns attributes for a transfer request from a source well to the child
    # plate. This method is invoked by the 'transfer_request_attributes' for
    # each filtered source well.
    #
    # @param source_well [Well] the source well
    # @param child_plate [Plate] the child plate
    # @param additional_parameters [Hash] additional parameters provided by well_filter
    # @return [Hash] the attributes for the transfer request for the source well
    #
    def request_hash(source_well, child_plate, additional_parameters)
      destination_location = get_destination_location(source_well)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.well_at_location(destination_location)&.uuid
      }.merge(additional_parameters)
    end
  end
end
