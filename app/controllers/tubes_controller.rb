class TubesController < LabWareController
  write_inheritable_attribute :creation_message, 'The tubes have been created'

  def locate_lab_ware_identified_by(id)
    api.multiplexed_library_tube.find(params[:id])
  end

  def presenter_for(tube)
    Presenters::TubePresenter.new(
      :api  => api,
      :tube => tube
    )
  end
end
