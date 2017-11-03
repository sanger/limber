# frozen_string_literal: true

module Presenters
  class StandardPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator
  end
end
