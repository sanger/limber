module StateChangers
  class DefaultStateChanger
    attr_reader :labware_uuid, :labware, :api
    private :api
    attr_reader :user_uuid

    def initialize(api, labware_uuid, user_uuid)
      @api, @labware_uuid, @user_uuid = api, labware_uuid, user_uuid
    end

    def move_to!(state, reason = nil)
      state_details = {
        :target       => labware_uuid,
        :user         => user_uuid,
        :target_state => state,
        :reason       => reason
      }

      api.state_change.create!(state_details)
    end

  end

  def self.lookup_for(purpose_uuid)
    details = Settings.purposes[purpose_uuid] or raise "Unknown purpose UUID: #{purpose_uuid}"
    details[:state_changer_class].constantize
  end
end
