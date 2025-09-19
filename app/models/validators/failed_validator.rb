# frozen_string_literal: true

module Validators
  # Displays a warning if libraries on the plate have been cancelled or failed
  # but the well itself still appears active.
  class FailedValidator < ActiveModel::Validator
    def validate(presenter)
      problem_wells = active_wells_with_terminated_requests(presenter.labware)
      return true if problem_wells.empty?

      affected_range = WellHelpers.formatted_range(problem_wells, presenter.size)

      presenter.errors.add(
        :submission,
        "on this plate has some failed wells (#{affected_range}). You should not carry out further work. " \
        'Any further work conducted from this plate will run into issues at the end of the pipeline.'
      )
    end

    def active_wells_with_terminated_requests(labware)
      labware.wells.filter_map do |well|
        # If the well is inactive or has no active requests, skip it
        next if well.inactive? || well.active_requests.empty?

        well.location if well.active_requests.all?(&:failed?)
      end
    end
  end
end
