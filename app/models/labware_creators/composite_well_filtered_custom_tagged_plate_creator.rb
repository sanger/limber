# frozen_string_literal: true

module LabwareCreators
  # This class extends the functionality of the `CustomTaggedPlate` labware creator
  # by adding well filtering capabilities using the `WellFilterComposite` class.
  #
  # ## Key Features:
  # - Associates a `WellFilter` instance of type WellFilterComposite with the labware creator.
  # ## Use Case:
  # This class is particularly useful in scenarios where:
  # - A single well contains multiple requests of different types.
  #   - Some requests are in a 'closed' state, while others are 'pending' (result of partial submissions).
  #   - Only a subset of wells needs to be processed or filtered based on specific criteria.
  # - A single well contains single request
  #
  # By applying composite well filtering, this class ensures that only the relevant requests in
  # well are processed and thereby creating transfer requests only for them.
  #
  # ## Example 1:
  # Suppose a well contains two requests:
  # - Request 1: Type 'request_type_a', State 'pending'
  # - Request 2: Type 'request_type_b', State 'closed'
  # Using this class, the well filter will allow processing of Request 1 while ignoring Request 2.
  #
  ## Example 2:
  # Suppose a well contains one request:
  # - Request 1: Type 'request_type_a', State 'pending'
  #  Using this class, the well filter will allow processing of Request 1.
  # @see LabwareCreators::CustomTaggedPlate
  # @see LabwareCreators::WellFilterComposite
  class CompositeWellFilteredCustomTaggedPlateCreator < CustomTaggedPlate
    include LabwareCreators::WellFilterBehaviour

    self.page = 'custom_tagged_plate'

    # Creates if not exists and returns the WellFilter instance associated with
    # the labware creator.
    #
    # @return [WellFilter] The WellFilter instance.
    def well_filter
      @well_filter ||= LabwareCreators::WellFilterComposite.new(creator: self)
    end
  end
end
