class PlatesController < ApplicationController

  PLATE_STATES = {
    'Pending'  => 'pending',
    'Started'  => 'started',
    'Passed'   => 'passed',
    'Canceled' => 'canceled',
    'Failed'   => 'failed'
  }

  before_filter :get_printers_and_lables, :on => [ :show, :update ]
  
  def show
    # Should the look up be done inside the plate form object?
    @plate = api.plate.find(params[:id])

    @plate_form = Forms::PlateForm.new(
      :api   => api,
      :plate => @plate
    )

    # TODO move into sub-class of plate
    @plate_states = PLATE_STATES

    respond_to do |format|
      format.html { render :show }
    end
  end

  def update
    @plate_states = PLATE_STATES
    @plate        = api.plate.find(params[:id])

    # @plate_form = Forms::PlateForm.new(
      # :api   => api,
      # :plate => @plate,
      # :state => params[:plate][:state]
    # )

    # @plate_form.save!

    api.state_change.create!(
      :target       => @plate.uuid,
      :target_state => params[:plate][:state]
    )


    # Refresh the plate...
    @plate = api.plate.find(params[:id])

    respond_to do |format|
      format.html { render :show }
    end
  end


  # Private Stuff...

  def get_printers_and_lables
    # This needs to be done properly through the barcode printing API...
    @barcode_label = BarcodeLabel.new({:printer => :BARCODE_PRINTER_NOT_SET})
    @printers      = { "H104_bd" => :h104_bd, "G206_bc" => :g206_bc }
  end
  private :get_printers_and_lables
end
