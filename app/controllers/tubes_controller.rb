# frozen_string_literal: true

class TubesController < LabwareController
  private

  def locate_labware_identified_by(_id)
    api.multiplexed_library_tube.find(params[:id])
  end
end
