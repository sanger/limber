# frozen_string_literal: true

module StateChangers # rubocop:todo Style/Documentation
  class StateChangeError < StandardError; end

  class DefaultStateChanger # rubocop:todo Style/Documentation
    attr_reader :labware_uuid, :api
    private :api
    attr_reader :user_uuid

    FILTER_FAILS_ON = ['qc_complete'].freeze

    def initialize(api, labware_uuid, user_uuid)
      @api = api
      @labware_uuid = labware_uuid
      @user_uuid = user_uuid
    end

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

    def contents_for(target_state)
      return nil unless FILTER_FAILS_ON.include?(target_state)

      labware.wells.reject { |w| w.state == 'failed' }.map(&:location)
    end

    def labware
      @labware ||= api.plate.find(labware_uuid)
    end
  end

  def self.lookup_for(purpose_uuid)
    (details = Settings.purposes[purpose_uuid]) || raise("Unknown purpose UUID: #{purpose_uuid}")
    details[:state_changer_class].constantize
  end

  # Plate state changer to automatically complete specified work requests.
  class AutomaticPlateStateChanger < DefaultStateChanger
    def initialize(api, labware_uuid, user_uuid)
      super
    end

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

    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      super
      complete_outstanding_requests
    end

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
