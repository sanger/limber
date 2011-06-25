class PlatesController < LabWareController
  def locate_lab_ware_identified_by(id)
    api.plate.find(params[:id]).coerce
  end

  def presenter_for(plate)
    Presenters::PlatePresenter.lookup_for(plate).new(
      :api   => api,
      :plate => plate
    )
  end
end
