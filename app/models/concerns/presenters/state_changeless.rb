# frozen_string_literal: true

module Presenters
  # Include in presenters that suppress state changes under all circumstances
  module StateChangeless
    def control_state_change
      # You cannot change the state
    end

    def default_state_change
      # You cannot change the state
    end
  end
end
