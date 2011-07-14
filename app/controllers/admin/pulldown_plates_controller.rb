class Admin::PulldownPlatesController < PlatesController

  # This controller shouldn't be used for "showing" labware directly
  # unless it's part of an edit.
  undef :show, :fail_wells

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
    # carry out any state changes...
  end

end
