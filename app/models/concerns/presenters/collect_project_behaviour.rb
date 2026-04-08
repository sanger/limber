# frozen_string_literal: true

# Include in a presenter which needs to collect a project from the user before allowing submission creation
module Presenters::CollectProjectBehaviour
  def collect_project?
    return false if purpose_config[:presenter_class].is_a?(String)

    purpose_config.dig(:presenter_class, :args, :collect_project) || false
  end
end
