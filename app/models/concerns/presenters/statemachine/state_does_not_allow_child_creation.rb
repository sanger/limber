# frozen_string_literal: true

module Presenters::Statemachine
  # Prevent creation of child assets while in this state
  module StateDoesNotAllowChildCreation
    extend ActiveSupport::Concern

    included do
      def control_additional_creation(&)
        # Does nothing because you can't!
      end
    end
  end
end
