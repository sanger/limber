# frozen_string_literal: true

module Presenters
  class MinimalPcrPlatePresenter < MinimalPlatePresenter
    self.state_transition_name_scope = :pcr
  end
end
