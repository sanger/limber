module Validators
  class SuboptimalValidator < ActiveModel::Validator
    def validate(presenter)
      if presenter.labware.wells.any?(&:suboptimal?)
        presenter.errors.add(:wells,'contain suboptimal aliquots')
      end
    end
  end
end
