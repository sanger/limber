# frozen_string_literal: true

# A State changer is responsible for transitioning the state of a plate, or
# individual wells.
module StateChangers
  class StateChangeError < StandardError; end

  # The Default State changer is used by the vast majority of plates. It creates
  # a simple StateChange record in Sequencescape, specifying the new 'target-state'
  # As a result, Sequencescape will attempt to transition the entire plate, or the
  # specified wells.
  class DefaultStateChanger
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
      state_details = {
        target: labware_uuid,
        user: user_uuid,
        target_state: state,
        reason: reason,
        customer_accepts_responsibility: customer_accepts_responsibility,
        contents: contents_for(state)
      }
      api.state_change.create!(state_details)
    end
    # rubocop:enable Style/OptionalBooleanParameter

    def contents_for(target_state)
      return nil unless FILTER_FAILS_ON.include?(target_state)

      # determine list of well locations requiring the state change
      well_locations_filtered = labware.wells.reject { |w| w.state == 'failed' }.map(&:location)

      # if no wells are in failed state then no need to send the contents subset
      return nil if well_locations_filtered.length == labware.wells.length

      well_locations_filtered
    end

    def labware
      @labware ||= api.plate.find(labware_uuid)
    end
  end

  def self.lookup_for(purpose_uuid)
    (details = Settings.purposes[purpose_uuid]) || raise("Unknown purpose UUID: #{purpose_uuid}")
    details[:state_changer_class].constantize
  end

  # The tube state changer is used by Tubes. It works the same way as the default
  # state changer but does not need to handle a subset of wells like the plate.
  class TubeStateChanger < DefaultStateChanger
    # Tubes have no wells so contents is always empty
    def contents_for(_target_state)
      nil
    end
  end

  # Plate state changer to automatically complete specified work requests.
  class AutomaticPlateStateChanger < DefaultStateChanger
    def v2_labware
      @v2_labware ||= Sequencescape::Api::V2.plate_for_completion(labware_uuid)
    end

    def purpose_uuid
      @purpose_uuid ||= v2_labware.purpose.uuid
    end

    def purpose_config
      @purpose_config ||= Settings.purposes[purpose_uuid]
    end

    def work_completion_request_type
      @work_completion_request_type ||= purpose_config[:work_completion_request_type]
    end

    # rubocop:todo Style/OptionalBooleanParameter
    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      super
      complete_outstanding_requests
    end
    # rubocop:enable Style/OptionalBooleanParameter

    def complete_outstanding_requests
      in_prog_submissions = v2_labware.in_progress_submission_uuids(request_type_key: work_completion_request_type)
      return if in_prog_submissions.blank?

      api.work_completion.create!(
        submissions: in_prog_submissions,
        target: v2_labware.uuid,
        user: user_uuid
      )
    end
  end
end
