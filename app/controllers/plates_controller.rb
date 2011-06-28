class PlatesController < LabWareController
  def locate_lab_ware_identified_by(id)
    api.plate.find(id).coerce
  end

  def presenter_for(plate)
    Presenters::PlatePresenter.lookup_for(plate).new(
      :api   => api,
      :plate => plate
    )
  end

  before_filter :locate_lab_ware, :on => :fail_wells

  def fail_wells
    api.state_change.create!(
      :target       => @lab_ware.uuid,
      :contents     => params[:plate][:wells].select { |_,v| v == '1' }.map(&:first),
      :target_state => 'failed',
      :reason       => 'Unspecified'
    )
    redirect_to(pulldown_plate_path(@lab_ware), :notice => 'Selected wells have been failed')
  end
end
