# frozen_string_literal: true

class TubeCreationController < CreationController
  def redirection_path(form)
    url_for(form.child)
  end

  def create
    creator_params[:parent_uuid] ||= parent_uuid
    @labware_creator = labware_creator(creator_params)
    @labware_creator.save!
    respond_to do |format|
      format.html { redirect_to_creator_child(@labware_creator) }
    end
  end

  private

  def creator_params
    params.require(:tube)
  end

  def parent_uuid
    params[:limber_tube_id] || params[:limber_plate_id]
  end
end
