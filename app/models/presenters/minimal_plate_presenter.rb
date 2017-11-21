# frozen_string_literal: true

module Presenters
  class MinimalPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard
    self.summary_partial = 'labware/plates/minimal_summary'
    self.well_failure_states = []

    def number_of_wells
      total_number_of_wells
    end

    # This is a lie.
    def tagged?
      true
    end

    # We don't want to load the wells here.
    def prepare; end
  end
end
