# frozen_string_literal: true

module LabwareCreators
  # This class is a subclass of StampedPlate but it reorders the wells from
  # columns to rows on the child plate. It compresses the wells in the child
  # plate; there will not be any gaps corresponding to the source wells that
  # were filtered out.
  class StampedPlateReorderingColumnsToRows < StampedPlate
    include LabwareCreators::StampedPlateReorderingValidator

    # This method is called by the well filter to receive the input wells for
    # filtering. It is overridden here to ensure that the wells are specified
    # in columns order. The well filter preserves the order of the wells when
    # the output is returned by its filtered_wells method.
    #
    # @return [Array<Well>] the wells in the plate in column order
    def labware_wells
      parent.wells_in_columns
    end

    # This method provides a mapping between the specified source well and the
    # corresponding destination well on the child plate. It is overridden here
    # to ensure that the wells are reordered from columns to rows. It is called
    # by the transfer_request_attributes method while building the transfer
    # requests.
    #
    # @param source_well [Well] the source well to find the destination well for
    # @param child_plate [Plate] the child plate to transfer material
    # @param additional_parameters [Hash] additional parameters provided by the
    #   well filter for the source well
    #
    # @return [Hash] the mapping between source well and destination well
    def request_hash(source_well, child_plate, additional_parameters)
      { source_asset: source_well.uuid, target_asset: reordering(source_well, child_plate)&.uuid }.merge(
        additional_parameters
      )
    end

    private

    # Returns the destination well for the specified source well on the child.
    #
    # @param source_well [Well] the source well to find the destination well for
    # @param child_plate [Plate] the child plate to transfer material
    #
    # @return [Well] the destination well on the child plate
    def reordering(source_well, child_plate)
      reordering_hash(child_plate)[source_well]
    end

    # Returns a hash mapping between the source wells and the destination wells.
    #
    # @param child_plate [Plate] the child plate to transfer material
    #
    # @return [Hash] the mapping between source wells and destination wells
    def reordering_hash(child_plate)
      @reordering_hash ||=
        well_filter
          .filtered_wells
          .each_with_object({})
          .with_index { |(source, hash), index| hash[source] = child_plate.wells_in_rows[index] }
    end
  end
end
