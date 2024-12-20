# frozen_string_literal: true

module Validators
  # Displays a warning if the requests on the plate have already been completed
  class InProgressValidator < ActiveModel::Validator
    def validate(presenter)
      return true unless presenter.labware.any_complete_requests?

      presenter.errors.add(
        :submission,
        '(active) is not present for this labware. ' \
          'Any further work conducted from this plate may run into issues at the end of the pipeline.'
      )
    end
  end
end
