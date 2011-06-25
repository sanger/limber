class PlatesController < ApplicationController
  before_filter :get_printers, :on => [ :show, :update ]

  def show
    # Should the look up be done inside the plate_presenter  object?
    @plate = api.plate.find(params[:id])

    @plate_presenter = Presenters.lookup_for(@plate).new(
      :api   => api,
      :plate => @plate
    )
    # debugger

    respond_to do |format|
      format.html { render @plate_presenter.page }
    end
  end

  def update
    @plate        = api.plate.find(params[:id])

    api.state_change.create!(
      :target       => @plate.uuid,
      :target_state => params[:plate][:state]
    )

    respond_to do |format|
      format.html { redirect_to :action => :show, :id => params[:id] }
    end
  end


  # Private Stuff...

  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers
end
