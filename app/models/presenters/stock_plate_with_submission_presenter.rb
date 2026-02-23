# frozen_string_literal: true

module Presenters

    class StockPlateWithSubmissionPresenter < PlatePresenter
        include Presenters::Statemachine::Submission
        include Presenters::SubmissionBehaviour
        include Presenters::StockBehaviour
        # include Presenters::StateChangeless
        include Presenters::Statemachine::DoesNotAllowLibraryPassing

        self.allow_well_failure_in_states = []
        self.style_class = 'stock'

        validates_with Validators::SuboptimalValidator
        validates_with Validators::ActiveRequestValidator
    end
end