# frozen_string_literal: true

module Validators
  # Displays a warning if wells are active (ie. not empty/failed/cancelled) and
  # yet don't have active requests associated with them.
  class ActiveRequestValidator < ActiveModel::Validator
    def validate(presenter)
      problem_wells = active_wells_without_active_requests(presenter.labware)
      return true if problem_wells.empty?

      problem_wells.each do |error, wells|
        affected_range = WellHelpers.formatted_range(wells, presenter.size)

        presenter.errors.add(
          :wells,
          "on this plate (#{affected_range}) have #{error}. You should not carry out further work. " \
          'Any further work conducted from this plate will run into issues at the end of the pipeline.'
        )
      end
    end

    def active_wells_without_active_requests(labware)
      labware
        .wells
        .each_with_object(Hash.new { |h, i| h[i] = [] }) do |well, store|
          next if well.inactive? || well.active_requests.present?

          well_error = error_for(well)
          store[well_error] << well.location
        end
    end

    def error_for(well)
      if well.all_requests.empty?
        'no associated requests'
      elsif well.all_requests.all?(&:cancelled?)
        'cancelled requests'
      else
        'requests not recognized by Limber'
      end
    end
  end
end
