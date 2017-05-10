# frozen_string_literal: true

class TubesController < LabwareController
  def locate_labware_identified_by(_id)
    api.multiplexed_library_tube.find(params[:id])
  end

  def presenter_for(labware)
    Presenters.lookup_for(labware).new(
      api: api,
      labware: labware
    )
  end
end
