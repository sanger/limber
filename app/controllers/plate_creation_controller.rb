class PlateCreationController < CreationController
  write_inheritable_attribute :creation_message, 'New plate created.'

  def form_lookup(form_attributes = params)
    Settings.plate_purposes[form_attributes[:plate_purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    illumina_b_plate_path(form.child.uuid)
  end
end
