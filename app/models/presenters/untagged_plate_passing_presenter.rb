# frozen_string_literal: true

module Presenters
  #
  # The UntaggedPlatePassingPresenter is used in MDA and allows passing before
  # libraries are tagged.
  # TODO: Really this decision is a property of the request, so probably belongs in the
  # intended 'pipelines' configuration
  class UntaggedPlatePassingPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator

    # Libraries don't need to be tagged to get passed
    def libraries_passable?
      passable_request_types.present?
    end
  end
end
