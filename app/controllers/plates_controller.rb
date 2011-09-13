class PlatesController < LabWareController
  def locate_lab_ware_identified_by(id)
    api.plate.find(id).coerce.tap { |plate| plate.after_load }
  end

  def presenter_for(plate)
    Presenters::PlatePresenter.lookup_for(plate).new(
      :api   => api,
      :plate => plate
    )
  end

  before_filter :locate_lab_ware, :on => :fail_wells

  def fail_wells
    wells_to_fail = params[:plate][:wells].select { |_,v| v == '1' }.map(&:first)
    if wells_to_fail.empty?
      redirect_to(pulldown_plate_path(@lab_ware), :notice => 'No wells were selected to fail')
    else
      api.state_change.create!(
        :user         => current_user_uuid,
        :target       => @lab_ware.uuid,
        :contents     => wells_to_fail,
        :target_state => 'failed',
        :reason       => 'Unspecified'
      )
      redirect_to(pulldown_plate_path(@lab_ware), :notice => 'Selected wells have been failed')
    end
  end
end
