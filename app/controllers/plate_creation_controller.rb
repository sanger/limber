# frozen_string_literal: true

class PlateCreationController < CreationController
  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end

  private

  def creator_params
    params.require(:plate)
  end
end
