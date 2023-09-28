# frozen_string_literal: true

module LabwareCreators
    # These creators handle a partial submission of wells on their
    # parent plate, and use a well filter to select those wells with requests that have
    # the correct request type, library type and request state.
    class PartialStampedPlateWithoutDilution < StampedPlate
      # The well filter will be used to identify the parent wells to be taken forward.
      # Filters on request type, library type and state.
      def well_filter
        @well_filter ||= WellFilterAllowingPartials.new(creator: self, request_state: 'pending')
      end
    end
  end
  