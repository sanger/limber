# frozen_string_literal: true

module Presenters
  class UnknownPlatePresenter < PlatePresenter # rubocop:todo Style/Documentation
    include Presenters::Statemachine::Shared
    include Presenters::Statemachine::StateDoesNotAllowChildCreation
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    validate :add_unknown_plate_warnings

    def robot?
      false
    end

    def well_failing_applicable?
      false
    end

    def label
      Labels::PlateLabel.new(labware)
    end

    def add_unknown_plate_warnings
      errors.add(
        :plate,
        "type '#{labware.purpose_name}' is not a limber plate. " \
        'Perhaps you are using the wrong pipeline application?'
      )
    end

    def default_printer
      :plate_a
    end
  end
end
