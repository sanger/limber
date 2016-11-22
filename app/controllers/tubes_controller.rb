# frozen_string_literal: true

class TubesController < LabwareController
  self.creation_message = 'The tubes have been created'

  def locate_labware_identified_by(_id)
    api.multiplexed_library_tube.find(params[:id])
  end

  def presenter_for(labware)
    Presenters::TubePresenter.lookup_for(labware).new(
      api: api,
      labware: labware
    )
  end
end
