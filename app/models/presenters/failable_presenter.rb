# frozen_string_literal: true

module Presenters
  class FailablePresenter < StandardPresenter
    self.well_failure_states = [:passed]
  end
end
