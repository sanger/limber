class TubesController < CreationController

  def form_lookup(*_)
    Forms::TubesForm
  end

  def redirection_path(form)
    plate_path(form.parent.uuid)
  end
end
