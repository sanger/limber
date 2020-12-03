# frozen_string_literal: true

module Presenters
  class UnknownTubePresenter < TubePresenter # rubocop:todo Style/Documentation
    include Presenters::Statemachine::Standard
    include Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    validate :add_unknown_tube_warnings

    def well_failing_applicable?
      false
    end

    def add_unknown_plate_warnings
      errors.add(:plate,
                 "type '#{labware.purpose.name}' is not a limber tube. Perhaps you are using the wrong pipeline application?")
    end

    def default_printer
      :tube
    end
  end
end
