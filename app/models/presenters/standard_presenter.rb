# frozen_string_literal: true

module Presenters
  class StandardPresenter < PlatePresenter
    include Presenters::Statemachine
  end
end
