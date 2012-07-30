module StateChangers
  class DefaultStateChanger
    attr_reader :labware_uuid
    attr_reader :api
    private :api
    attr_reader :user_uuid

    def initialize(api, labware_uuid, user_uuid)
      @api, @labware_uuid, @user_uuid = api, labware_uuid, user_uuid
    end

    def move_to!(state, reason = nil)
      api.state_change.create!(
        :target       => labware_uuid,
        :user         => user_uuid,
        :target_state => state,
        :reason       => reason
      )
    end
  end

  def self.lookup_for(plate_purpose_uuid)
    plate_details = Settings.plate_purposes[plate_purpose_uuid] or raise UnknownPlateType, plate
    plate_details[:state_changer_class].constantize
  end
end
