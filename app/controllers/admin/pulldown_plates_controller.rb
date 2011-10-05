class Admin::PulldownPlatesController < PlatesController

  # This controller shouldn't be used for "showing" labware directly
  # unless it's part of an edit.
  undef :show, :fail_wells

  # Called by the update method inherited from LabWareController
  # the same as in LabWareController but uses params[:card_id] instead
  # of current_user_id
  def state_changer_for(labware)
    StateChangers.lookup_for(labware).new(api, labware, find_user_by_swipecard(params[:card_id]))
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

  def update
    super
  rescue => exception
    flash[:alert] = exception.message

    respond_to do |format|
      format.html { redirect_to edit_admin_plate_path(params[:id]) }
    end
  end

end
