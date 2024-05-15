# frozen_string_literal: true

module Presenters
  class DonorPoolingPlatePresenter < StandardPresenter
    validates_with Validators::RequiredNumberOfCellsValidator
  end
end
