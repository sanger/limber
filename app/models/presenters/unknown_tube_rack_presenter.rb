# frozen_string_literal: true

module Presenters
  # Presenter for unknown tube racks
  class UnknownTubeRackPresenter < TubeRackPresenter
    include Presenters::Statemachine::Shared
    include Presenters::Statemachine::StateDoesNotAllowChildCreation
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    validate :add_unknown_tube_rack_warnings

    def robot?
      false
    end

    def well_failing_applicable?
      false
    end

    def add_unknown_tube_rack_warnings
      errors.add(
        :tube_rack,
        "type '#{labware.purpose_name}' is not a limber tube rack. " \
        'Perhaps you are using the wrong pipeline application?'
      )
    end

    def label
      Labels::PlateLabel.new(labware)
    end

    # NB. tube racks have etched barcodes and are not usually printed
    def default_printer
      :plate_a
    end
  end
end
