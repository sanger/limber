# frozen_string_literal: true

module Presenters
  # A stock tube presenter is used for tubes just entering the pipeline.
  # It shows a preview of the tube, but prevents well failure and state changes.
  # In addition it also detects common scenarios which may indicate problems
  # with the submission.
  class StockTubePresenter < TubePresenter
    include Presenters::Statemachine::Standard
    include Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    def well_failing_applicable?
      false
    end

    def default_printer
      :tube
    end
  end
end
