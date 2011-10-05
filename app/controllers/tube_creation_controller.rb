class TubeCreationController < CreationController
  def form_lookup(*_)
    Forms::TubesForm
  end

  def redirection_path(form)
    pulldown_plate_path(form.parent.uuid)
  end
end
