# frozen_string_literal: true

# show => Looks up the presenter for the giver purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
class TubesController < LabwareController
  private

  def locate_labware_identified_by(_id)
    api.multiplexed_library_tube.find(params[:id])
  end
end
