# frozen_string_literal: true

class TubeCreationController < CreationController
  def redirection_path(form)
    url_for(form.child)
  end

  def create
    tube_params[:parent_uuid] ||= parent_uuid
    @creator_form = creator_form(tube_params)

    @creator_form.save!
    respond_to do |format|
      format.html { redirect_to_creator_child(@creator_form) }
    end
  end

  private

  def tube_params
    params.require(:tube)
  end

  def parent_uuid
    params[:limber_tube_id] || params[:limber_plate_id]
  end
end
