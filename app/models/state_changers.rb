# frozen_string_literal: true

# A State changer is responsible for transitioning the state of labware and its receptacles where applicable.
#
# Hierarchy:
#  - BaseStateChanger
#    - PlateStateChanger
#      - AutomaticPlateStateChanger [includes AutomaticBehaviour]
#    - TubeStateChanger
#      - AutomaticTubeStateChanger [includes AutomaticBehaviour]
#
module StateChangers
  # Plate state changer to automatically complete specified work requests.
  # This is the abstract behaviour.
  # #
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

    def labware
      raise 'Must be implemented on subclass'
    end

    def self.lookup_for(purpose_uuid)
      (details = Settings.purposes[purpose_uuid]) || raise("Unknown purpose UUID: #{purpose_uuid}")
      details[:state_changer_class].constantize
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
      @labware ||= api.plate.find(labware_uuid)
    end
  end

  # The tube state changer is used by Tubes. It works the same way as the default
  # plate state changer but does not need to handle a subset of wells like the plate.
  class TubeStateChanger < BaseStateChanger
    # Tubes have no wells so contents is always empty
    def contents_for(_target_state)
      nil
    end

    def labware
      raise 'Tubes are not supported by API V1'
    end
  end

  # This version of the AutomaticLabwareStateChanger is used by Plates.
  class AutomaticPlateStateChanger < PlateStateChanger
    include AutomaticBehaviour

    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2.plate_for_completion(labware_uuid)
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
