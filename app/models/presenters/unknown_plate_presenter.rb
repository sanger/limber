# frozen_string_literal: true

module Presenters
  class UnknownPlatePresenter < PlatePresenter # rubocop:todo Style/Documentation
    include Presenters::Statemachine::Shared
    include Presenters::Statemachine::StateDoesNotAllowChildCreation
    include Presenters::Statemachine::DoesNotAllowLibraryPassing

    validate :add_unknown_plate_warnings

    def well_failing_applicable?
      false
    end

    def label
      Labels::PlateLabel.new(labware)
    end

    def add_unknown_plate_warnings
      errors.add(:plate,
                 "type '#{labware.purpose.name}' is not a limber plate. "\
                 'Perhaps you are using the wrong pipeline application?')
    end

    def default_printer
      :plate_a
    end

    def control_state_change
      # You cannot change the state of the unknown plate
    end

    def default_state_change
      # You cannot change the state of the unknown plate
    end
  end
end
