# frozen_string_literal: true

class TubeCreationController < CreationController
  def redirection_path(form)
    url_for(form.child)
  end

  private

  def creator_params
    params.require(:tube)
  end
end
