# frozen_string_literal: true

module Presenters::Statemachine
  # Prevent creation of child assets while in this state
  module StateDoesNotAllowChildCreation
    def control_additional_creation(&block)
      # Does nothing because you can't!
    end
  end
end
