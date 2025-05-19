# frozen_string_literal: true

module LabwareCreators
  # This class extends the functionality of the `CustomTaggedPlate` labware creator
  # by adding well filtering capabilities. It allows partial well filtering
  # using the `WellFilterAllowingPartials` class.
  #
  # ## Key Features:
  # - Associates a `WellFilter` instance of type WellFilterAllowingPartials with the labware creator.
  # ## Use Case:
  # This class is particularly useful in scenarios where:
  # - A single well contains multiple requests of different types.
  # - Some requests are in a 'closed' state, while others are 'pending' (result of partial submissions).
  # - Only a subset of wells needs to be processed or filtered based on specific criteria.
  #
  # By applying partial well filtering, this class ensures that only the relevant requests in
  # well are processed and thereby creating transfer requests only for them, improving accuracy in workflows.
  #
  # ## Example:
  # Suppose a well contains two requests:
  # - Request 1: Type 'request_type_a', State 'pending'
  # - Request 2: Type 'request_type_b', State 'closed'
  #
  # Using this class, the well filter will allow processing of Request 1 while ignoring Request 2.

  # @see LabwareCreators::CustomTaggedPlate
  # @see LabwareCreators::WellFilterAllowingPartials
  class PartialWellFilteredCustomTaggedPlateCreator < CustomTaggedPlate
    include LabwareCreators::WellFilterBehaviour
    self.page = 'custom_tagged_plate'
    self.should_populate_wells_with_pool = false # parent is a V2 plate

    # Creates if not exists and returns the WellFilter instance associated with
    # the labware creator.
    #
    # @return [WellFilter] The WellFilter instance.
    def well_filter
      @well_filter ||= LabwareCreators::WellFilterAllowingPartials.new(creator: self)
    end
  end
end
