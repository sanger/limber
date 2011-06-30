module StateChangers
  class DefaultStateChanger
    attr_reader :labware
    attr_reader :api
    private :api

    def initialize(api, labware)
      @api, @labware = api, labware
    end

    def move_to!(state, reason = nil)
      api.state_change.create!(
        :target       => labware.uuid,
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
