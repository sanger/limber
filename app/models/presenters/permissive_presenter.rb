# frozen_string_literal: true

module Presenters
  #
  # Class PermissivePresenter provides a presenter which allows plate creation
  # even when the plate is pending
  #
  class PermissivePresenter < PlatePresenter
    include Presenters::Statemachine::Permissive
  end
end
