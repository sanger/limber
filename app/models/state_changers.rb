# frozen_string_literal: true

module StateChangers
  class StateChangeError < StandardError; end

  class DefaultStateChanger
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
end
