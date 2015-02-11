#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013 Genome Research Ltd.
module StateChangers

  class StateChangeError < StandardError ; end

  class DefaultStateChanger
    attr_reader :labware_uuid, :labware, :api
    private :api
    attr_reader :user_uuid

    def initialize(api, labware_uuid, user_uuid)
      @api, @labware_uuid, @user_uuid = api, labware_uuid, user_uuid
    end

    def move_to!(state, reason = nil, customer_accepts_responsibility = false)
      state_details = {
        :target       => labware_uuid,
        :user         => user_uuid,
        :target_state => state,
        :reason       => reason,
        :customer_accepts_responsibility => customer_accepts_responsibility
      }

      api.state_change.create!(state_details)
    end

  end

  def self.lookup_for(purpose_uuid)
    details = Settings.purposes[purpose_uuid] or raise "Unknown purpose UUID: #{purpose_uuid}"
    details[:state_changer_class].constantize
  end
end
