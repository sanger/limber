# frozen_string_literal: true

module Presenters
  class UnknownTubePresenter < UubePresenter
    include Presenters::Statemachine::Standard
    include Statemachine::DoesNotAllowLibraryPassing

    validate :add_unknown_tube_warnings

    def well_failing_applicable?
      false
    end

    def add_unknown_plate_warnings
      errors.add(:plate, "type '#{labware.purpose.name}' is not a limber tube. Perhaps you are using the wrong pipeline application?")
    end

    def control_state_change
      # You cannot change the state of the unknown plate
    end

    def default_state_change
      # You cannot change the state of the unknown plate
    end

    def default_printer
      :plate_a
    end
  end
end
