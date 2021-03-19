# frozen_string_literal: true

module Presenters
  class MinimalPlatePresenter < PlatePresenter # rubocop:todo Style/Documentation
    include Presenters::Statemachine::Standard

    self.summary_partial = 'labware/plates/minimal_summary'
    self.allow_well_failure_in_states = []

    validates_with Validators::ActiveRequestValidator

    def number_of_wells
      size
    end

    def csv_file_links
      []
    end

    # This is a lie.
    # TODO: Work out a more elegant way to handle this
    # We may not actually need to, as this is mainly used to work out
    # if we should allow library passing. Which I'm not sure we want to allow anyway
    # for most minimal plates.
    def tagged?
      true
    end
  end
end
