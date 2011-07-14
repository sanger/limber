class Admin::PulldownPlatesController < PlatesController

  # This controller shouldn't be used for "showing" labware directly
  # unless it's part of an edit.
  undef :show, :fail_wells

  # Called by the update method inherited from LabWareController
  # the same as in LabWareController but uses params[:user_id] instead
  # of current_user_id
  def state_changer_for(labware)
    StateChangers.lookup_for(labware).new(api, labware, find_user_by_swipecard(params[:user_id]))
  end

  def edit
    @presenter = Presenters::AdminPresenter.new(
      :api => api,
      :plate => @lab_ware
    )

    if @presenter.stock_plate?
       render :stock_plate
    else
      respond_to do |format|
        format.html
      end
    end
  end

end
