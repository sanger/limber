class PlateCreationController < CreationController
  write_inheritable_attribute :creation_message, 'The plate has been created'

  def form_lookup(form_attributes = params)
    Settings.plate_purposes[form_attributes[:plate_purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    pulldown_plate_path(form.child.uuid)
  end
end
