# frozen_string_literal: true

module Presenters
  class QcPlatePresenter < PlatePresenter
    include Presenters::Statemachine
    include StateDoesNotAllowChildCreation
  end
end
