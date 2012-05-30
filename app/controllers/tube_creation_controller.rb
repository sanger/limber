class TubeCreationController < CreationController
  def form_lookup(*_)
    Forms::TubesForm
  end

  def redirection_path(form)
    illumina_b_plate_path(form.parent.uuid)
  end
end
