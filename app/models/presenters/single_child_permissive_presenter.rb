# frozen_string_literal: true

module Presenters
  #
  # Class SingleChildPermissivePresenter provides a presenter which allows creation of a single plate
  # even when the plate is pending
  #
  class SingleChildPermissivePresenter < PlatePresenter
    include Presenters::Statemachine::SingleChildPermissive

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator
  end
end
