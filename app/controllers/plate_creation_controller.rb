# frozen_string_literal: true

class PlateCreationController < CreationController
  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end

  def create
    @labware_creator = labware_creator(params[:plate])
    @labware_creator.save!
    respond_to do |format|
      format.html { redirect_to_creator_child(@labware_creator) }
    end
  end

  def parent_uuid
    params[:limber_plate_id]
  end
end
