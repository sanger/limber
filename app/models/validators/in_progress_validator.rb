# frozen_string_literal: true

module Validators
  class InProgressValidator < ActiveModel::Validator
    def validate(presenter)
      return true unless presenter.labware.any_complete_requests?

      presenter.errors.add(:libraries, 'on this plate have already been completed. Any further work conducted from this plate may run into issues at the end of the pipeline.')
    end
  end
end
