# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of child assets in this state
  module StateAllowsChildCreation
    extend ActiveSupport::Concern

    included do
      def control_additional_creation
        yield
      end
    end
  end
end
