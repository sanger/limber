# frozen_string_literal: true

class PlateCreationController < CreationController
  self.creation_message = 'New empty plate added to system.'

  def form_lookup(form_attributes = params)
    Settings.purposes[form_attributes[:purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end
end
