class PlateCreationController < CreationController
  def form_lookup(form_attributes = params)
    Settings.plate_purposes[form_attributes[:plate_purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    pulldown_plate_path(form.child.uuid)
  end
end
