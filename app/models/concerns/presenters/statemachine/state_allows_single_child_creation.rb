# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of a single child asset in this state
  module StateAllowsSingleChildCreation
    def control_additional_creation
      yield if self.child_assets.nil? || self.child_assets.empty?
    end
  end
end
