module StateChangers
  class DefaultStateChanger
    attr_reader :labware
    attr_reader :api
    private :api
    attr_reader :user_uuid

    def initialize(api, labware, user_uuid)
      @api, @labware, @user_uuid = api, labware, user_uuid
    end

    def move_to!(state, reason = nil)
      api.state_change.create!(
        :target       => labware.uuid,
        :user         => user_uuid,
        :target_state => state,
        :reason       => reason
      )
    end
  end

  def self.lookup_for(plate)
    plate_details = Settings.plate_purposes[plate.plate_purpose.uuid] or raise UnknownPlateType, plate
    plate_details[:state_changer_class].constantize
  end
end
