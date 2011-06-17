class CreationController < ApplicationController

  def new
    @creation_form  = Forms.lookup_form(params[:plate_purpose_uuid]).new(
      :api                => api,
      :parent_uuid        => params[:plate_id],
      :plate_purpose_uuid => params[:plate_purpose_uuid]
    )

    respond_to do |format|
      # TODO Sort this look up out!
      format.html { render @creation_form.class.const_get(:PARTIAL) }
    end
  end

  def create
    @creation_form = Forms.lookup_form(params[:plate][:plate_purpose_uuid]).new(
      params[:plate].merge(:api => api)
    )

    if @creation_form.save
      respond_to do |format|
        format.html { redirect_to plate_path(@creation_form.child.uuid) }
      end
    else
      raise "Not saving #{@creation_form.class} form...."
    end
  end
end
