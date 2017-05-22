# frozen_string_literal: true

module Validators
  class SuboptimalValidator < ActiveModel::Validator
    def validate(presenter)
      return true unless presenter.labware.wells.any?(&:suboptimal?)
      presenter.errors.add(:wells, 'contain suboptimal aliquots')
    end
  end
end
