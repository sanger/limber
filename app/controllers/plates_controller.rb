class PlatesController < LabwareController

  def locate_labware_identified_by(id)
    api.plate.find(id).coerce.tap { |plate| plate.populate_wells_with_pool }
  end

  def presenter_for(plate)
    Presenters::PlatePresenter.lookup_for(plate).new(
      :api   => api,
      :plate => plate
    )
  end

  def fail_wells
    wells_to_fail = params[:plate][:wells].select { |_,v| v == '1' }.map(&:first)

    if wells_to_fail.empty?
      redirect_to(illumina_b_plate_path(params[:id]), :notice => 'No wells were selected to fail')
    else
      api.state_change.create!(
        :user         => current_user_uuid,
        :target       => params[:id],
        :contents     => wells_to_fail,
        :target_state => 'failed',
        :reason       => 'Individual Well Failure'
      )
      redirect_to(illumina_b_plate_path(params[:id]), :notice => 'Selected wells have been failed')
    end
  end
end
