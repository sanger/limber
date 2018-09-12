# frozen_string_literal: true

class PlateCreationController < CreationController
  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end

  def create
    @labware_creator = labware_creator(creator_params)
    @labware_creator.save!
    respond_to do |format|
      format.html { redirect_to_creator_child(@labware_creator) }
    end
  end

  private

  def creator_params
    params.require(:plate)
  end

  def parent_uuid
    params[:limber_tube_id] || params[:limber_plate_id]
  end
end
