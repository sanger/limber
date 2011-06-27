class LabWareController < ApplicationController
  before_filter :locate_lab_ware, :on => [ :show, :update ]
  def locate_lab_ware
    @lab_ware = locate_lab_ware_identified_by(params[:id])
  end
  private :locate_lab_ware

  before_filter :get_printers, :on => [ :show, :update ]
  def get_printers
    @printers = api.barcode_printer.all
  end
  private :get_printers

  def show
    @presenter = presenter_for(@lab_ware)
    respond_to do |format|
      format.html { render @presenter.page }
    end
  end

  def update
    api.state_change.create!(
      :target       => @lab_ware.uuid,
      :target_state => params[:state],
      :reason       => params[:reason]
    )

    respond_to do |format|
      format.html { redirect_to :action => :show, :id => @lab_ware.uuid }
    end
  end
end
