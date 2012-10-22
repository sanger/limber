class TubesController < LabwareController
  write_inheritable_attribute :creation_message, 'The tubes have been created'

  def locate_labware_identified_by(id)
    api.multiplexed_library_tube.find(params[:id])
  end

  def presenter_for(labware)
    Presenters::TubePresenter.lookup_for(labware).new(
      :api     => api,
      :labware => labware
    )
  end

end
