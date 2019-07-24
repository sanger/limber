# frozen_string_literal: true

module Presenters
  #
  # The StandardPresenter is used for the majority of plates. It shows a preview
  # of the plate itself, and permits state changes, well failures and child
  # creation when passed.
  #
  class StandardPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator
  end
end
