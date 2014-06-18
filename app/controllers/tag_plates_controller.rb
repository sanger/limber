class TagPlatesController < ApplicationController

  def show
    qcable = Presenters::QcablePresenter.new(api.qcable.find(params[:id]))
    respond_to do |format|
      format.json { render :json => {'qcable'=>qcable } }
    end
  end

end
