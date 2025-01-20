# frozen_string_literal: true

# A State changer is responsible for transitioning the state of labware and its receptacles where applicable.
#
# Hierarchy:
#  - BaseStateChanger
#    - PlateStateChanger
#      - AutomaticPlateStateChanger [includes AutomaticBehaviour]
#    - TubeRackStateChanger
#      - AutomaticTubeRackStateChanger [includes AutomaticBehaviour]
#    - TubeStateChanger
#      - AutomaticTubeStateChanger [includes AutomaticBehaviour]
#
module StateChangers
  def self.lookup_for(purpose_uuid)
    (details = Settings.purposes[purpose_uuid]) || raise("Unknown purpose UUID: #{purpose_uuid}")
    details[:state_changer_class].constantize
  end

  # Plate state changer to automatically complete specified work requests.
  # This is the abstract behaviour.
  #
  # Must include v2_labware method in the including class
  module AutomaticBehaviour
    def purpose_uuid
      @purpose_uuid ||= v2_labware.purpose.uuid
    end

    def purpose_config
      @purpose_config ||= Settings.purposes[purpose_uuid]
    end

    def work_completion_request_types
      @work_completion_request_types ||= parse_work_completion_request_types
    end

    # config can be a single request type or an array of request types
    # convert them here into a consistent array format
    def parse_work_completion_request_types
      config = purpose_config[:work_completion_request_type]
      return config if config.is_a?(Array)

      [config]
    end

    # rubocop:todo Style/OptionalBooleanParameter
    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      super
      complete_outstanding_requests
    end

    # rubocop:enable Style/OptionalBooleanParameter

    def complete_outstanding_requests
      in_progress_submission_uuids =
        v2_labware.in_progress_submission_uuids(request_types_to_complete: work_completion_request_types)
      return if in_progress_submission_uuids.blank?

      api.work_completion.create!(submissions: in_progress_submission_uuids, target: v2_labware.uuid, user: user_uuid)
    end
  end

  # The Base state changer that contains common behaviour for all state changers.
  class BaseStateChanger
    attr_reader :labware_uuid, :api, :user_uuid
    private :api

    FILTER_FAILS_ON = %w[qc_complete failed cancelled].freeze

    def initialize(api, labware_uuid, user_uuid)
      @api = api
      @labware_uuid = labware_uuid
      @user_uuid = user_uuid
    end

    # rubocop:todo Style/OptionalBooleanParameter

    # This method performs a state change on the labware by creating a new state change record
    # using the Sequencescape API. It includes details such as the contents to be changed,
    # whether the customer accepts responsibility, the reason for the change, the target state,
    # the target UUID, and the user UUID.
    #
    # @param state [String] the target state to move the labware to
    # @param reason [String, nil] the reason for the state change (optional)
    # @param customer_accepts_responsibility [Boolean] whether the customer accepts responsibility
    # for the state change (default: false)
    # @return [Sequencescape::Api::V2::StateChange] the created state change record
    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      Sequencescape::Api::V2::StateChange.create!(
        contents: contents_for(state),
        customer_accepts_responsibility: customer_accepts_responsibility,
        reason: reason,
        target_state: state,
        target_uuid: labware_uuid,
        user_uuid: user_uuid
      )
    end

    # rubocop:enable Style/OptionalBooleanParameter

    # This method determines the well locations that require a state change based on the target state.
    # If the target state is not in the FILTER_FAILS_ON list, it returns nil.
    # It filters out wells that are in the 'failed' state and collects their locations.
    # If all wells are in the 'failed' state, it returns nil.
    # Otherwise, it returns the locations of the wells that are not in the 'failed' state.
    #
    # @param target_state [String] the state to check against the FILTER_FAILS_ON list
    # @return [Array<String>, nil] an array of well locations requiring the state change, or nil if no change is needed
    def contents_for(_target_state)
      raise 'Must be implemented on subclass' # pragma: no cover
    end

    def labware
      raise 'Must be implemented on subclass' # pragma: no cover
    end
  end

  # The Plate State changer is used by the vast majority of plates. It creates
  # a simple StateChange record in Sequencescape, specifying the new 'target-state'
  # As a result, Sequencescape will attempt to transition the entire plate, or the
  # specified wells.
  class PlateStateChanger < BaseStateChanger
    def contents_for(target_state)
      return nil unless FILTER_FAILS_ON.include?(target_state)

      # determine list of well locations requiring the state change
      well_locations_filtered = labware.wells.reject { |w| w.state == 'failed' }.map(&:location)

      # if no wells are in failed state then no need to send the contents subset
      return nil if well_locations_filtered.length == labware.wells.count

      well_locations_filtered
    end

    def labware
      @labware ||= Sequencescape::Api::V2::Plate.find_by(uuid: labware_uuid)
    end
  end

  # The tube rack state changer is used by TubeRacks.
  # It contains racked tubes.
  class TubeRackStateChanger < BaseStateChanger
    # This method determines the coordinates of tubes that require a state change based on the target state.
    # If the target state is not in the FILTER_FAILS_ON list, it returns nil.
    # It filters out tubes that are in the 'failed' state and collects their coordinates.
    # If all tubes are in the 'failed' state, it returns nil.
    # Otherwise, it returns the coordinates of the tubes that are not in the 'failed' state.
    #
    # @param target_state [String] the state to check against the FILTER_FAILS_ON list
    # @return [Array<String>, nil] an array of tube coordinates requiring the state change, or nil if no
    # change is needed
    def contents_for(target_state)
      return nil unless FILTER_FAILS_ON.include?(target_state)

      # determine list of tubes requiring the state change
      # TODO: why does this check specifically for 'failed' when the FILTER_FAILS_ON is a list with several states?
      racked_tubes_locations_filtered = labware.racked_tubes.reject { |rt| rt.tube.state == 'failed' }.map(&:coordinate)

      # if no tubes are in the target state then no need to send the contents subset (state changer assumes all
      #  will change)
      return nil if racked_tubes_locations_filtered.length == labware.racked_tubes.count

      # NB. if all tubes are already in the target state then this method will return an empty array
      # TODO: is this correct behaviour?
      racked_tubes_locations_filtered
    end

    def labware
      @labware ||= Sequencescape::Api::V2::TubeRack.find({ uuid: labware_uuid }).first
    end
  end

  # The tube state changer is used by Tubes. It works the same way as the default
  # plate state changer but does not need to handle a subset of wells like the plate.
  class TubeStateChanger < BaseStateChanger
    # Tubes have no wells so contents is always empty
    def contents_for(_target_state)
      nil
    end

    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2::Tube.find_by(uuid: labware_uuid)
    end

    def labware
      @labware ||= v2_labware
    end
  end

  # This version of the AutomaticLabwareStateChanger is used by Plates.
  class AutomaticPlateStateChanger < PlateStateChanger
    include AutomaticBehaviour

    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2.plate_for_completion(labware_uuid)
    end
  end

  # This version of the AutomaticLabwareStateChanger is used by TubeRacks.
  class AutomaticTubeRackStateChanger < TubeRackStateChanger
    include AutomaticBehaviour

    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2.tube_rack_for_completion(labware_uuid)
    end

    def labware
      @labware ||= v2_labware
    end
  end

  # This version of the AutomaticLabwareStateChanger is used by Tubes.
  class AutomaticTubeStateChanger < TubeStateChanger
    include AutomaticBehaviour

    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2.tube_for_completion(labware_uuid)
    end

    def labware
      @labware ||= v2_labware
    end
  end
end
