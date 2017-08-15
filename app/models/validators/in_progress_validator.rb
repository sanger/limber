# frozen_string_literal: true

module Validators
  class InProgressValidator < ActiveModel::Validator
    def validate(presenter)
      return true unless presenter.labware.pools.any? { |_uuid, pool_info| pool_info['pool_complete'] }
      presenter.errors.add(:libraries, 'on this plate have already been completed. Any further work conducted from this plate may run into issues at the end of the pipeline.')
    end
  end
end
