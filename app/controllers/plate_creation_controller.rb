# frozen_string_literal: true

class PlateCreationController < CreationController
  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end

  def create
    @creator_form = creator_form(params[:plate])
    @creator_form.save!
    respond_to do |format|
      format.html { redirect_to_creator_child(@creator_form) }
    end
  end

  def parent_uuid
    params[:limber_plate_id]
  end
end
