# frozen_string_literal: true

module Validators
  # Displays a warning if the requests on the plate have already been completed
  class InProgressValidator < ActiveModel::Validator
    def validate(presenter)
      return true unless presenter.labware.any_non_create_asset_requests_completed?

      first_request = presenter.labware.active_non_create_asset_requests.first

      return true if first_request.nil?

      presenter.errors.add(
        :submission,
        "Requests of type #{first_request.request_type.name} have already been down the pipeline and were completed."
      )
    end
  end
end
