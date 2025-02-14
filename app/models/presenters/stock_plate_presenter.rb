# frozen_string_literal: true

module Presenters
  # A stock plate presenter is used for plates just entering the pipeline.
  # It shows a preview of the plate, but prevents well failure and state changes.
  # In addition it also detects common scenarios which may indicate problems
  # with the submission.
  # State of stock plates is a little complicated currently, as it can't depend
  # on transfer requests into the plate. As a result, wells on stock plates may
  # have a state of 'unknown.' As a result, stock wells inherit their styling
  # from the plate itself.
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard
    include Presenters::StockBehaviour

    self.allow_well_failure_in_states = []

    # Stock style class causes well state to inherit from plate state.
    self.style_class = 'stock'

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator
  end
end
