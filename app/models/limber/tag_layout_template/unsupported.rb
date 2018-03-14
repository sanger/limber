# frozen_string_literal: true

module Limber::TagLayoutTemplate::Unsupported
  def generate_tag_layout(_plate)
    # Extends our template when we have an unknown layout algorithm
    # Ensures addition of new template behaviours can be made without
    # requiring Limber updates.
    throw :unacceptable_tag_layout
  end
end
