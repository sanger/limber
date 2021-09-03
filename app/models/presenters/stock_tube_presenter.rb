# frozen_string_literal: true

module Presenters
  # A stock tube presenter is used for tubes just entering the pipeline.
  # It shows a preview of the tube, but prevents well failure and state changes.
  # In addition it also detects common scenarios which may indicate problems
  # with the submission.
  class StockTubePresenter < TubePresenter
    include Presenters::Statemachine::StateAllowsChildCreation
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    def state
      "passed"
    end
  end
end
